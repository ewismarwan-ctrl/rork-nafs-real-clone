import Foundation
import CoreLocation
import Adhan

@MainActor
@Observable
class PrayerTimeService {
    var prayerTimes: [PrayerTime] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var locationName: String = ""

    private let locationService = LocationService()
    private var hasFetched: Bool = false
    private(set) var lastComputedLat: Double?
    private(set) var lastComputedLon: Double?
    private var lastComputedDay: Int?

    /// True only when prayer times were computed from a real device location.
    var hasRealLocationData: Bool { lastComputedLat != nil && lastComputedLon != nil }

    static let offsetsKey = "nafs_prayerOffsetsMinutes"

    static func offsets() -> [PrayerName: Int] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: offsetsKey),
              let raw = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        var result: [PrayerName: Int] = [:]
        for (key, value) in raw {
            if let name = PrayerName(rawValue: key) { result[name] = value }
        }
        return result
    }

    static func setOffset(_ minutes: Int, for prayer: PrayerName) {
        var current: [String: Int] = [:]
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: offsetsKey),
           let raw = try? JSONDecoder().decode([String: Int].self, from: data) {
            current = raw
        }
        let previous = current[prayer.rawValue] ?? 0
        current[prayer.rawValue] = minutes
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: offsetsKey)
        }

        guard previous != minutes else { return }

        // Adjusting the prayer time invalidates today's completion for that
        // prayer — the blocker should reactivate against the new time.
        PrayerCompletionStore.resetCompletion(prayer, on: .now)

        // Mirror the reset into the App Group so widgets / extensions see it.
        if let shared = UserDefaults(suiteName: "group.app.rork.4lq2ucv31aityltnkks3n.nafs") {
            let f = DateFormatter()
            f.calendar = Calendar(identifier: .gregorian)
            f.timeZone = TimeZone.current
            f.dateFormat = "yyyy-MM-dd"
            let key = "nafs_prayerCompleted_\(prayer.rawValue)_\(f.string(from: Date()))"
            shared.removeObject(forKey: key)
        }

        // Clear any persisted active lock for this prayer so the engine can
        // reactivate once the new time is reached.
        let activeKey = "nafs_prayerActiveLock"
        if defaults.string(forKey: activeKey) == prayer.rawValue {
            defaults.removeObject(forKey: activeKey)
            defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
        }
    }

    func invalidateCache() {
        lastComputedDay = nil
        lastComputedLat = nil
        lastComputedLon = nil
    }

    func fetchPrayerTimes(method: PrayerCalculationMethod, madhab: AsrMadhab = .shafi) async {
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermission()
            try? await Task.sleep(for: .seconds(2))
        }

        if locationService.lastLatitude == nil {
            locationService.requestLocation()
            for _ in 0..<20 {
                try? await Task.sleep(for: .milliseconds(500))
                if locationService.lastLatitude != nil { break }
            }
        }

        guard let lat = locationService.lastLatitude,
              let lon = locationService.lastLongitude else {
            generateFallbackTimes()
            return
        }

        // Guard against tiny location jitter causing large recomputation
        // Only recompute if coordinates moved a meaningful amount OR the day changed
        let today = Calendar.current.component(.dayOfYear, from: Date.now)
        if let oldLat = lastComputedLat, let oldLon = lastComputedLon,
           let oldDay = lastComputedDay, oldDay == today {
            let dLat = abs(oldLat - lat)
            let dLon = abs(oldLon - lon)
            // ~0.02 degrees ≈ 2km. Below this, keep prior result to avoid visible jumps.
            if dLat < 0.02 && dLon < 0.02 && !prayerTimes.isEmpty {
                return
            }
        }

        isLoading = true
        errorMessage = nil

        let resolvedMethod: PrayerCalculationMethod
        if method == .auto {
            resolvedMethod = Self.detectMethod(lat: lat, lon: lon)
        } else {
            resolvedMethod = method
        }

        let coords = Coordinates(latitude: lat, longitude: lon)
        var params = resolvedMethod.adhanParams
        params.madhab = (madhab == .hanafi) ? .hanafi : .shafi

        let cal = Calendar(identifier: .gregorian)
        let now = Date.now
        let components = cal.dateComponents([.year, .month, .day], from: now)

        guard let times = PrayerTimes(coordinates: coords, date: components, calculationParameters: params) else {
            generateFallbackTimes()
            isLoading = false
            return
        }

        let offsets = Self.offsets()

        let rawPrayers: [(PrayerName, Date)] = [
            (.fajr, times.fajr),
            (.dhuhr, times.dhuhr),
            (.asr, times.asr),
            (.maghrib, times.maghrib),
            (.isha, times.isha),
        ]

        var result: [PrayerTime] = []
        var foundNext = false

        for (name, rawDate) in rawPrayers {
            let offset = offsets[name] ?? 0
            let adjusted = rawDate.addingTimeInterval(TimeInterval(offset * 60))
            let rounded = Self.roundToMinute(adjusted)
            let isNext = !foundNext && rounded > now
            if isNext { foundNext = true }
            result.append(PrayerTime(id: name.rawValue, name: name, time: rounded, isNext: isNext))
        }

        if !foundNext, !result.isEmpty {
            result[0] = PrayerTime(id: result[0].name.rawValue, name: result[0].name, time: result[0].time, isNext: true)
        }

        prayerTimes = result
        hasFetched = true
        lastComputedLat = lat
        lastComputedLon = lon
        lastComputedDay = today
        reverseGeocode(lat: lat, lon: lon)
        isLoading = false
    }

    private static func roundToMinute(_ date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let seconds = comps.second ?? 0
        comps.second = 0
        var result = cal.date(from: comps) ?? date
        if seconds >= 30 {
            result = result.addingTimeInterval(60)
        }
        return result
    }

    static func detectMethod(lat: Double, lon: Double) -> PrayerCalculationMethod {
        if lat >= 15.0 && lat <= 55.0 && lon >= -130.0 && lon <= -50.0 {
            return .isna
        }
        if lat >= 13.0 && lat <= 55.0 && lon >= -25.0 && lon <= 45.0 {
            return .muslimWorldLeague
        }
        if lat >= 18.0 && lat <= 31.0 && lon >= 34.0 && lon <= 56.0 {
            return .ummAlQura
        }
        if lat >= 24.0 && lat <= 32.0 && lon >= 43.0 && lon <= 50.0 {
            return .gulf
        }
        if lat >= 28.0 && lat <= 42.0 && lon >= 25.0 && lon <= 45.0 {
            return .turkey
        }
        if lat >= 22.0 && lat <= 40.0 && lon >= 24.0 && lon <= 37.0 {
            return .egyptian
        }
        if lat >= 23.0 && lat <= 37.0 && lon >= 60.0 && lon <= 78.0 {
            return .karachi
        }
        if lat >= -10.0 && lat <= 8.0 && lon >= 95.0 && lon <= 141.0 {
            return .singapore
        }
        if lat >= 0.0 && lat <= 8.0 && lon >= 99.0 && lon <= 120.0 {
            return .singapore
        }
        if lat >= 25.0 && lat <= 40.0 && lon >= 44.0 && lon <= 63.0 {
            return .tehran
        }
        return .isna
    }

    /// Compute prayer times for the next N days (starting today) using current location.
    /// Returns one array of (name, time) per day. Used to keep widgets accurate across day rollovers.
    func computeUpcomingDays(method: PrayerCalculationMethod, madhab: AsrMadhab, days: Int) async -> [[(name: String, time: Date)]] {
        guard let lat = locationService.lastLatitude,
              let lon = locationService.lastLongitude else {
            return []
        }

        let resolvedMethod: PrayerCalculationMethod = (method == .auto)
            ? Self.detectMethod(lat: lat, lon: lon)
            : method

        let coords = Coordinates(latitude: lat, longitude: lon)
        var params = resolvedMethod.adhanParams
        params.madhab = (madhab == .hanafi) ? .hanafi : .shafi

        let cal = Calendar(identifier: .gregorian)
        let offsets = Self.offsets()
        var result: [[(name: String, time: Date)]] = []

        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: offset, to: .now) else { continue }
            let comps = cal.dateComponents([.year, .month, .day], from: day)
            guard let times = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params) else { continue }

            let raw: [(PrayerName, Date)] = [
                (.fajr, times.fajr),
                (.dhuhr, times.dhuhr),
                (.asr, times.asr),
                (.maghrib, times.maghrib),
                (.isha, times.isha),
            ]
            let dayTimes: [(name: String, time: Date)] = raw.map { name, rawDate in
                let off = offsets[name] ?? 0
                let adjusted = rawDate.addingTimeInterval(TimeInterval(off * 60))
                return (name: name.rawValue, time: Self.roundToMinute(adjusted))
            }
            result.append(dayTimes)
        }

        return result
    }

    private func reverseGeocode(lat: Double, lon: Double) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                self?.locationName = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea ?? ""
            }
        }
    }

    private func generateFallbackTimes() {
        let cal = Calendar.current
        let now = Date.now
        let base = cal.startOfDay(for: now)

        let times: [(PrayerName, Int, Int)] = [
            (.fajr, 5, 15),
            (.dhuhr, 12, 30),
            (.asr, 15, 45),
            (.maghrib, 18, 30),
            (.isha, 20, 0),
        ]

        var result: [PrayerTime] = []
        var foundNext = false

        for (name, hour, minute) in times {
            let date = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
            let isNext = !foundNext && date > now
            if isNext { foundNext = true }
            result.append(PrayerTime(id: name.rawValue, name: name, time: date, isNext: isNext))
        }

        if !foundNext, !result.isEmpty {
            result[0] = PrayerTime(id: result[0].name.rawValue, name: result[0].name, time: result[0].time, isNext: true)
        }

        prayerTimes = result
    }
}

extension PrayerCalculationMethod {
    var adhanParams: CalculationParameters {
        switch self {
        case .auto, .isna: return CalculationMethod.northAmerica.params
        case .muslimWorldLeague: return CalculationMethod.muslimWorldLeague.params
        case .egyptian: return CalculationMethod.egyptian.params
        case .ummAlQura, .makkah: return CalculationMethod.ummAlQura.params
        case .karachi: return CalculationMethod.karachi.params
        case .kuwait: return CalculationMethod.kuwait.params
        case .qatar: return CalculationMethod.qatar.params
        case .singapore: return CalculationMethod.singapore.params
        case .turkey: return CalculationMethod.turkey.params
        case .tehran: return CalculationMethod.tehran.params
        case .gulf: return CalculationMethod.dubai.params
        }
    }
}
