import Foundation

nonisolated final class QuranService: Sendable {
    static let shared = QuranService()

    private let baseURL = "https://api.quran.com/api/v4"
    private let translationID = 20
    private let cacheDirectoryName = "QuranCache"

    func fetchSurah(number: Int) async throws -> [QuranAyah] {
        guard number >= 1, number <= 114 else { throw QuranError.invalidURL }
        let expectedCount = SurahInfo.all[number - 1].ayahCount

        do {
            let fetched = try await fetchFromAPI(surahNumber: number)
            try validate(ayahs: fetched, expectedCount: expectedCount, surahNumber: number)
            saveToCache(ayahs: fetched, surahNumber: number)
            return fetched
        } catch {
            if let cached = loadFromCache(surahNumber: number),
               (try? validate(ayahs: cached, expectedCount: expectedCount, surahNumber: number)) != nil {
                return cached
            }
            throw error
        }
    }

    private func fetchFromAPI(surahNumber: Int) async throws -> [QuranAyah] {
        var components = URLComponents(string: "\(baseURL)/verses/by_chapter/\(surahNumber)")
        components?.queryItems = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "words", value: "false"),
            URLQueryItem(name: "translations", value: "\(translationID)"),
            URLQueryItem(name: "fields", value: "text_uthmani"),
            URLQueryItem(name: "per_page", value: "300")
        ]
        guard let url = components?.url else { throw QuranError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw QuranError.serverError
        }

        let decoded = try JSONDecoder().decode(QuranComVersesResponse.self, from: data)

        var result: [QuranAyah] = []
        for verse in decoded.verses {
            let arabic = verse.text_uthmani.trimmingCharacters(in: .whitespacesAndNewlines)
            let translationText = verse.translations?.first.map { stripHTML($0.text) } ?? ""
            let global = SurahInfo.globalAyahNumber(surah: surahNumber, ayahInSurah: verse.verse_number)
            result.append(QuranAyah(
                id: global,
                numberInSurah: verse.verse_number,
                arabicText: arabic,
                translation: translationText
            ))
        }
        return result
    }

    private func stripHTML(_ text: String) -> String {
        var output = text
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            let range = NSRange(output.startIndex..., in: output)
            output = regex.stringByReplacingMatches(in: output, options: [], range: range, withTemplate: "")
        }
        output = output
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validate(ayahs: [QuranAyah], expectedCount: Int, surahNumber: Int) throws {
        guard ayahs.count == expectedCount else { throw QuranError.validationFailed }
        for (index, ayah) in ayahs.enumerated() {
            let expectedNumber = index + 1
            if ayah.numberInSurah != expectedNumber { throw QuranError.validationFailed }
            if ayah.arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw QuranError.validationFailed
            }
        }
    }

    // MARK: - Cache

    private func cacheURL(surahNumber: Int) -> URL? {
        guard let dir = try? FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ) else { return nil }
        let folder = dir.appendingPathComponent(cacheDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("surah_\(surahNumber).json")
    }

    private func saveToCache(ayahs: [QuranAyah], surahNumber: Int) {
        guard let url = cacheURL(surahNumber: surahNumber) else { return }
        let cacheable = ayahs.map { CachedAyah(id: $0.id, numberInSurah: $0.numberInSurah, arabicText: $0.arabicText, translation: $0.translation) }
        if let data = try? JSONEncoder().encode(cacheable) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func loadFromCache(surahNumber: Int) -> [QuranAyah]? {
        guard let url = cacheURL(surahNumber: surahNumber),
              let data = try? Data(contentsOf: url),
              let cached = try? JSONDecoder().decode([CachedAyah].self, from: data) else { return nil }
        return cached.map { QuranAyah(id: $0.id, numberInSurah: $0.numberInSurah, arabicText: $0.arabicText, translation: $0.translation) }
    }
}

// MARK: - Quran.com API DTOs

nonisolated struct QuranComVersesResponse: Codable, Sendable {
    let verses: [QuranComVerse]
}

nonisolated struct QuranComVerse: Codable, Sendable {
    let id: Int
    let verse_number: Int
    let verse_key: String
    let text_uthmani: String
    let translations: [QuranComTranslation]?
}

nonisolated struct QuranComTranslation: Codable, Sendable {
    let resource_id: Int
    let text: String
}

nonisolated struct CachedAyah: Codable, Sendable {
    let id: Int
    let numberInSurah: Int
    let arabicText: String
    let translation: String
}

nonisolated enum QuranError: Error, Sendable, LocalizedError {
    case invalidURL
    case serverError
    case parsingError
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError: return "Could not reach Quran server"
        case .parsingError: return "Could not parse Quran data"
        case .validationFailed: return "Quran data did not match the expected structure"
        }
    }
}
