import Foundation

nonisolated final class QuranService: Sendable {
    static let shared = QuranService()

    private let bismillahText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

    func fetchSurah(number: Int) async throws -> [QuranAyah] {
        let urlString = "https://api.alquran.cloud/v1/surah/\(number)/editions/quran-uthmani,en.sahih"
        guard let url = URL(string: urlString) else { throw QuranError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw QuranError.serverError
        }

        let decoded = try JSONDecoder().decode(QuranEditionsResponse.self, from: data)
        guard decoded.data.count >= 2 else { throw QuranError.parsingError }

        let arabicAyahs = decoded.data[0].ayahs
        let englishAyahs = decoded.data[1].ayahs

        var result: [QuranAyah] = []

        for (arabic, english) in zip(arabicAyahs, englishAyahs) {
            var arabicText = arabic.text
            var numberInSurah = arabic.numberInSurah

            if number == 1 {
                result.append(QuranAyah(
                    id: arabic.number,
                    numberInSurah: numberInSurah,
                    arabicText: arabicText,
                    translation: english.text
                ))
                continue
            }

            if number != 9 && arabic.numberInSurah == 1 {
                arabicText = removeBismillahPrefix(from: arabicText)
                if arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
            }

            result.append(QuranAyah(
                id: arabic.number,
                numberInSurah: numberInSurah,
                arabicText: arabicText,
                translation: english.text
            ))
        }

        return result
    }

    private func removeBismillahPrefix(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix(bismillahText) {
            let remaining = String(trimmed.dropFirst(bismillahText.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return remaining
        }

        let shortBismillah = "بسم الله الرحمن الرحيم"
        if trimmed.hasPrefix(shortBismillah) {
            let remaining = String(trimmed.dropFirst(shortBismillah.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return remaining
        }

        return text
    }
}

nonisolated enum QuranError: Error, Sendable, LocalizedError {
    case invalidURL
    case serverError
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError: return "Could not reach server"
        case .parsingError: return "Could not parse Quran data"
        }
    }
}
