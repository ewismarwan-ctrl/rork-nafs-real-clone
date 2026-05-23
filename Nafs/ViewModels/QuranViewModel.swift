import SwiftUI

@Observable
@MainActor
class QuranViewModel {
    var surahs: [SurahInfo] = SurahInfo.all
    var searchText: String = ""
    var ayahs: [QuranAyah] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var bookmarks: [QuranBookmark] = []

    var lastReadSurah: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_lastReadSurah") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_lastReadSurah") }
    }

    var lastReadAyah: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_lastReadAyah") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_lastReadAyah") }
    }

    var filteredSurahs: [SurahInfo] {
        guard !searchText.isEmpty else { return surahs }
        let query = searchText.lowercased()
        return surahs.filter {
            $0.englishName.lowercased().contains(query) ||
            $0.meaning.lowercased().contains(query) ||
            $0.arabicName.contains(query) ||
            "\($0.id)" == query
        }
    }

    init() {
        loadBookmarks()
    }

    func fetchSurah(number: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await QuranService.shared.fetchSurah(number: number)
            ayahs = fetched
            lastReadSurah = number
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func isBookmarked(surah: Int, ayah: Int) -> Bool {
        bookmarks.contains { $0.surahNumber == surah && $0.ayahNumberInSurah == ayah }
    }

    func toggleBookmark(surah: Int, ayah: QuranAyah, surahName: String) {
        if let idx = bookmarks.firstIndex(where: { $0.surahNumber == surah && $0.ayahNumberInSurah == ayah.numberInSurah }) {
            bookmarks.remove(at: idx)
        } else {
            let bm = QuranBookmark(
                surahNumber: surah,
                ayahNumberInSurah: ayah.numberInSurah,
                surahName: surahName,
                arabicSnippet: ayah.arabicText,
                translationSnippet: ayah.translation
            )
            bookmarks.insert(bm, at: 0)
        }
        saveBookmarks()
    }

    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "nafs_quranBookmarks")
        }
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: "nafs_quranBookmarks"),
              let saved = try? JSONDecoder().decode([QuranBookmark].self, from: data) else { return }
        bookmarks = saved
    }
}
