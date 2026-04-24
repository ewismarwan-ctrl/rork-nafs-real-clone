import SwiftUI

struct QuranListView: View {
    let appViewModel: AppViewModel
    let storeViewModel: StoreViewModel
    let audioPlayer: QuranAudioPlayer
    @State private var quranVM = QuranViewModel()
    @State private var selectedSurah: SurahInfo?
    @State private var showBookmarks: Bool = false
    @State private var showNafsAI: Bool = false
    @State private var showReciterPicker: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    reciterCard

                    if quranVM.lastReadSurah > 0 {
                        lastReadCard
                    }

                    if !quranVM.bookmarks.isEmpty {
                        bookmarkStrip
                    }

                    surahList
                }
                .padding(.top, 8)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(NafsStrings.tabQuran.localized)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $quranVM.searchText, prompt: NafsStrings.searchSurah.localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showNafsAI = true
                        } label: {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(NafsTheme.gold)
                        }
                        Button {
                            showBookmarks.toggle()
                        } label: {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(NafsTheme.gold)
                        }
                    }
                }
            }
            .navigationDestination(for: SurahInfo.self) { surah in
                SurahReaderView(surah: surah, quranVM: quranVM, audioPlayer: audioPlayer, appViewModel: appViewModel, storeViewModel: storeViewModel)
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarksSheet(quranVM: quranVM)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showNafsAI) {
                NavigationStack {
                    NafsAIView(appViewModel: appViewModel, storeViewModel: storeViewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") { showNafsAI = false }
                                    .foregroundStyle(NafsTheme.gold)
                            }
                        }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showReciterPicker) {
                ReciterPickerSheet(audioPlayer: audioPlayer, storeViewModel: storeViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var reciterCard: some View {
        Button {
            showReciterPicker = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(NafsStrings.chooseReciter.localized)
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(audioPlayer.selectedReciter.displayName)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                    Text(audioPlayer.selectedReciter.arabicName)
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.gold)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
            .padding(16)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    private var lastReadCard: some View {
        let surah = SurahInfo.all.first(where: { $0.id == quranVM.lastReadSurah })
        return Group {
            if let surah {
                NavigationLink(value: surah) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(NafsTheme.gold.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "book.fill")
                                .foregroundStyle(NafsTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NafsStrings.continueReading.localized)
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(NafsTheme.subtleText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text(surah.englishName)
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(NafsTheme.text)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    .padding(16)
                    .background(NafsTheme.gold.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var bookmarkStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NafsStrings.bookmarks.localized)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quranVM.bookmarks.prefix(5)) { bm in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bm.surahName)
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(NafsTheme.gold)
                            Text("Ayah \(bm.ayahNumberInSurah)")
                                .font(.system(.caption2))
                                .foregroundStyle(NafsTheme.subtleText)
                        }
                        .padding(10)
                        .background(NafsTheme.card)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }

    private var surahList: some View {
        LazyVStack(spacing: 0) {
            ForEach(quranVM.filteredSurahs) { surah in
                NavigationLink(value: surah) {
                    SurahRow(surah: surah)
                }
                if surah.id != quranVM.filteredSurahs.last?.id {
                    Divider()
                        .padding(.leading, 68)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct SurahRow: View {
    let surah: SurahInfo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(NafsTheme.gold.opacity(0.12))
                Text("\(surah.id)")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(surah.englishName)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                Text("\(surah.meaning) · \(surah.ayahCount) ayahs")
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Spacer()

            Text(surah.arabicName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(NafsTheme.gold)
        }
        .padding(.vertical, 12)
    }
}

private struct BookmarksSheet: View {
    let quranVM: QuranViewModel

    var body: some View {
        NavigationStack {
            if quranVM.bookmarks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 40))
                        .foregroundStyle(NafsTheme.subtleText)
                    Text("No bookmarks yet")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(quranVM.bookmarks) { bm in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(bm.surahName)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(NafsTheme.gold)
                                Text("Ayah \(bm.ayahNumberInSurah)")
                                    .font(.system(.caption))
                                    .foregroundStyle(NafsTheme.subtleText)
                            }
                            Text(bm.arabicSnippet)
                                .font(.system(.caption))
                                .foregroundStyle(NafsTheme.text)
                                .lineLimit(1)
                            Text(bm.translationSnippet)
                                .font(.system(.caption2))
                                .foregroundStyle(NafsTheme.subtleText)
                                .lineLimit(2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(NafsStrings.bookmarks.localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReciterPickerSheet: View {
    let audioPlayer: QuranAudioPlayer
    let storeViewModel: StoreViewModel
    @State private var showUpgradeSheet: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(NafsStrings.chooseReciter.localized)
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(NafsTheme.text)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(QuranReciter.allCases) { reciter in
                        let isSelected = audioPlayer.selectedReciter == reciter
                        let isLocked = !reciter.isFree && !storeViewModel.isPremium
                        Button {
                            if isLocked {
                                showUpgradeSheet = true
                            } else {
                                audioPlayer.saveReciter(reciter)
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(NafsTheme.gold.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(.caption))
                                        .foregroundStyle(NafsTheme.gold)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(reciter.displayName)
                                            .font(.system(.body, weight: .semibold))
                                            .foregroundStyle(isLocked ? NafsTheme.subtleText : NafsTheme.text)
                                        if isLocked {
                                            Image(systemName: "lock.fill")
                                                .font(.system(.caption2))
                                                .foregroundStyle(NafsTheme.gold)
                                        }
                                    }
                                    Text(reciter.arabicName)
                                        .font(.system(.subheadline))
                                        .foregroundStyle(isLocked ? NafsTheme.subtleText.opacity(0.6) : NafsTheme.gold)
                                }

                                Spacer()

                                if isLocked {
                                    Text("PRO")
                                        .font(.system(.caption2, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(NafsTheme.goldGradient)
                                        .clipShape(.capsule)
                                } else if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(.title3))
                                        .foregroundStyle(NafsTheme.gold)
                                }
                            }
                            .padding(14)
                            .background(NafsTheme.card)
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(isSelected && !isLocked ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected && !isLocked ? 2 : 1)
                            )
                        }
                        .sensoryFeedback(.selection, trigger: audioPlayer.selectedReciter)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradePaywallSheet(
                storeViewModel: storeViewModel,
                feature: "Premium Reciters",
                benefit: "Unlock all 9 world-renowned Quran reciters with Nafs Premium.",
                onDismiss: { showUpgradeSheet = false },
                onSuccess: { showUpgradeSheet = false }
            )
        }
    }
}
