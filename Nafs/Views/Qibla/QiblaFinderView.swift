import SwiftUI
import CoreLocation

@MainActor
@Observable
class QiblaViewModel: NSObject {
    var heading: Double = 0
    var qiblaAngle: Double = 0
    var userLatitude: Double?
    var userLongitude: Double?
    var cityName: String = ""
    var distanceToMeccaKm: Double = 0
    var distanceToMeccaMiles: Double = 0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var headingAccuracy: Double = -1
    var isCompassAvailable: Bool = true
    var locationError: String?

    private var locationManager: CLLocationManager?
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
    }

    func startUpdates() {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        self.locationManager = manager
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        } else if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func stopUpdates() {
        locationManager?.stopUpdatingHeading()
        locationManager?.stopUpdatingLocation()
    }

    var accuracyLevel: AccuracyLevel {
        if headingAccuracy < 0 { return .low }
        if headingAccuracy <= 10 { return .high }
        if headingAccuracy <= 25 { return .medium }
        return .low
    }

    var qiblaRelativeToNorth: Double {
        qiblaAngle - heading
    }

    private func calculateQibla() {
        guard let lat = userLatitude, let lon = userLongitude else { return }
        let userLat = lat * .pi / 180
        let userLon = lon * .pi / 180
        let meccaLat = 21.4225 * .pi / 180
        let meccaLon = 39.8262 * .pi / 180
        let deltaLon = meccaLon - userLon
        let y = sin(deltaLon) * cos(meccaLat)
        let x = cos(userLat) * sin(meccaLat) - sin(userLat) * cos(meccaLat) * cos(deltaLon)
        var angle = atan2(y, x) * 180 / .pi
        if angle < 0 { angle += 360 }
        qiblaAngle = angle

        let R = 6371.0
        let dLat = meccaLat - userLat
        let dLon = meccaLon - userLon
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(userLat) * cos(meccaLat) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        distanceToMeccaKm = R * c
        distanceToMeccaMiles = distanceToMeccaKm * 0.621371
    }

    private func reverseGeocode() {
        guard let lat = userLatitude, let lon = userLongitude else { return }
        let location = CLLocation(latitude: lat, longitude: lon)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                self?.cityName = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea ?? ""
            }
        }
    }

    nonisolated enum AccuracyLevel: Sendable {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return .green
            case .medium: return .orange
            case .low: return .red
            }
        }

        var label: String {
            switch self {
            case .high: return "High accuracy"
            case .medium: return "Medium accuracy"
            case .low: return "Low accuracy"
            }
        }
    }
}

extension QiblaViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            userLatitude = location.coordinate.latitude
            userLongitude = location.coordinate.longitude
            calculateQibla()
            reverseGeocode()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            heading = newHeading.magneticHeading
            headingAccuracy = newHeading.headingAccuracy
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
}

struct QiblaFinderView: View {
    var storeViewModel: StoreViewModel? = nil
    var isPremium: Bool = true
    @State private var viewModel = QiblaViewModel()
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        Group {
            if isPremium {
                qiblaContent
            } else if let store = storeViewModel {
                PremiumGateView(
                    icon: "location.north.fill",
                    title: L10n.text("Qibla Finder", "اتجاه القبلة"),
                    subtitle: L10n.text("Find the direction of Mecca with Nafs Premium.", "اعثر على اتجاه مكة مع نفس بريميوم."),
                    storeViewModel: store
                )
            }
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.text("Qibla Finder", "اتجاه القبلة"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var qiblaContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                    permissionDeniedView
                } else {
                    compassSection
                    detailsSection
                    instructionNote
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onAppear { viewModel.startUpdates() }
        .onDisappear { viewModel.stopUpdates() }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("القِبْلَة")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
            Text(L10n.text("Face this direction to pray", "توجه بهذا الاتجاه للصلاة"))
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
        }
    }

    private var compassSection: some View {
        ZStack {
            Circle()
                .fill(NafsTheme.background)
                .frame(width: 280, height: 280)
                .overlay {
                    GeometricPatternFallback(opacity: 0.04)
                        .clipShape(Circle())
                }
                .overlay(
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1.5)
                )

            CompassRing()
                .rotationEffect(.degrees(-viewModel.heading))

            QiblaNeedle()
                .rotationEffect(.degrees(viewModel.qiblaRelativeToNorth))

            CrescentStarMark(size: 24, color: NafsTheme.gold)
        }
        .frame(width: 280, height: 280)
        .animation(.easeOut(duration: 0.3), value: viewModel.heading)
        .animation(.easeOut(duration: 0.3), value: viewModel.qiblaAngle)
    }

    private var detailsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(L10n.text("Qibla: \(Int(viewModel.qiblaAngle))°", "القبلة: \(Int(viewModel.qiblaAngle))°"))
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.accuracyLevel.color)
                    .frame(width: 8, height: 8)
                Text(viewModel.accuracyLevel.label)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            if !viewModel.cityName.isEmpty {
                Text(viewModel.cityName)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
            }

            if viewModel.distanceToMeccaKm > 0 {
                Text(L10n.text("\(Int(viewModel.distanceToMeccaKm)) km / \(Int(viewModel.distanceToMeccaMiles)) miles from Mecca", "\(Int(viewModel.distanceToMeccaKm)) كم / \(Int(viewModel.distanceToMeccaMiles)) ميل من مكة"))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var instructionNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(NafsTheme.gold)
                .font(.system(.subheadline))
            Text(L10n.text("Hold your phone flat and parallel to the ground for the most accurate reading. Move away from metal objects and electronic devices.", "أمسك هاتفك بشكل مسطح وموازٍ للأرض للحصول على أدق قراءة. ابتعد عن الأجسام المعدنية والأجهزة الإلكترونية."))
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(NafsTheme.gold)

            Text(L10n.text("Nafs needs your location to calculate the Qibla direction. Please enable location access in Settings.", "نفس يحتاج موقعك لحساب اتجاه القبلة. يرجى تفعيل الموقع في الإعدادات."))
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)

            NafsButton(title: L10n.text("Open Settings", "فتح الإعدادات")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(30)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }
}

private struct CompassRing: View {
    private let cardinals: [(String, Double)] = [
        ("N", 0), ("E", 90), ("S", 180), ("W", 270)
    ]

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(NafsTheme.gold.opacity(0.5), lineWidth: 1.5)
                .frame(width: 260, height: 260)

            ForEach(0..<72, id: \.self) { i in
                let angle = Double(i) * 5
                let isMajor = i % 18 == 0
                let isMinor = i % 9 == 0
                Rectangle()
                    .fill(NafsTheme.gold.opacity(isMajor ? 0.8 : (isMinor ? 0.4 : 0.2)))
                    .frame(width: isMajor ? 1.5 : 0.8, height: isMajor ? 12 : (isMinor ? 8 : 5))
                    .offset(y: -122)
                    .rotationEffect(.degrees(angle))
            }

            ForEach(cardinals, id: \.0) { label, angle in
                Text(label)
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(label == "N" ? NafsTheme.gold : NafsTheme.text)
                    .offset(y: -105)
                    .rotationEffect(.degrees(angle))
            }
        }
    }
}

private struct QiblaNeedle: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 140, y: 30))
                path.addLine(to: CGPoint(x: 134, y: 130))
                path.addLine(to: CGPoint(x: 146, y: 130))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color(hex: "D4AF37"), Color(hex: "C8A96A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Path { path in
                path.move(to: CGPoint(x: 140, y: 250))
                path.addLine(to: CGPoint(x: 134, y: 150))
                path.addLine(to: CGPoint(x: 146, y: 150))
                path.closeSubpath()
            }
            .fill(NafsTheme.text.opacity(0.2))

            Circle()
                .fill(NafsTheme.gold)
                .frame(width: 10, height: 10)
                .position(x: 140, y: 140)
        }
        .frame(width: 280, height: 280)
    }
}
