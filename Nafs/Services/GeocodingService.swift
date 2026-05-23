import Foundation

nonisolated struct GeocodingResult: Identifiable, Sendable, Hashable {
    let id: String
    let city: String
    let state: String
    let country: String

    var displayName: String {
        if state.isEmpty {
            return "\(city), \(country)"
        }
        return "\(city), \(state), \(country)"
    }
}

nonisolated struct NominatimResult: Codable, Sendable {
    let place_id: Int
    let display_name: String
    let address: NominatimAddress?
}

nonisolated struct NominatimAddress: Codable, Sendable {
    let city: String?
    let town: String?
    let village: String?
    let state: String?
    let country: String?
}

nonisolated final class GeocodingService: Sendable {
    static let shared = GeocodingService()

    func searchCities(query: String, countryCode: String) async throws -> [GeocodingResult] {
        guard !query.isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(encoded)&countrycodes=\(countryCode)&format=json&addressdetails=1&limit=15&featuretype=city"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("NafsApp/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode([NominatimResult].self, from: data)

        var seen = Set<String>()
        var results: [GeocodingResult] = []
        for item in decoded {
            let city = item.address?.city ?? item.address?.town ?? item.address?.village ?? ""
            guard !city.isEmpty else { continue }
            let country = item.address?.country ?? ""
            let state = item.address?.state ?? ""
            let key = "\(city.lowercased())_\(state.lowercased())"
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            results.append(GeocodingResult(
                id: "\(item.place_id)",
                city: city,
                state: state,
                country: country
            ))
        }
        return results
    }
}
