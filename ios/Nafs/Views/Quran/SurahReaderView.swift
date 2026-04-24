import SwiftUI
import AVFoundation

struct SurahReaderView: View {
    let surah: SurahInfo
    let quranVM: QuranViewModel
    let audioPlayer: QuranAudioPlayer
    let appViewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var hapticTrigger: Int = 0
    @State private var selectedAyahId: Int?
    @State private var showAIForAyah: Bool = false
    @State private var aiContextText: String = ""
    @Environment(\.dismiss) private var dismiss

    private var showBismillah: Bool {
        surah.id != 1 && surah.id != 9
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    surahHeader

                    if quranVM.isLoading {
                        loadingView
                    } else if let error = quranVM.errorMessage {
                        errorView(error)
                    } else {
                        ayahList
                    }

                    Spacer(minLength: 40)
                }
            }
            .onChange(of: audioPlayer.currentGlobalAyah) { _, newAyah in
                guard newAyah > 0 else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(newAyah, anchor: .center)
                }
            }
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(surah.englishName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    audioPlayer.playSurah(surahNumber: surah.id, reciter: audioPlayer.selectedReciter, ayahs: quranVM.ayahs)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(.title3))
                        .foregroundStyle(NafsTheme.gold)
                }
            }
        }
        .task {
            await quranVM.fetchSurah(number: surah.id)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .sheet(isPresented: $showAIForAyah) {
            NavigationStack {
                NafsAIView(appViewModel: appViewModel, storeViewModel: storeViewModel, initialMessage: aiContextText)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { showAIForAyah = false }
                                .foregroundStyle(NafsTheme.gold)
                        }
                    }
            }
            .presentationDetents([.large])
        }
    }

    private var surahHeader: some View {
        VStack(spacing: 8) {
            Text(surah.arabicName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(NafsTheme.gold)
            Text(surah.englishName)
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text("\(surah.meaning) · \(surah.ayahCount) Ayahs")
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)

            if showBismillah {
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(NafsTheme.gold.opacity(0.3))
                        .frame(width: 60, height: 1)
                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                        .font(.custom("Geeza Pro", size: 30).weight(.semibold))
                        .foregroundStyle(NafsTheme.gold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(18)
                        .environment(\.layoutDirection, .rightToLeft)
                    Rectangle()
                        .fill(NafsTheme.gold.opacity(0.3))
                        .frame(width: 60, height: 1)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(NafsTheme.gold.opacity(0.04))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(NafsTheme.gold)
            Text(NafsStrings.loadingSurah.localized)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(NafsTheme.subtleText)
            Text(message)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
            Button(NafsStrings.retry.localized) {
                Task { await quranVM.fetchSurah(number: surah.id) }
            }
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(NafsTheme.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var ayahList: some View {
        LazyVStack(spacing: 0) {
            ForEach(quranVM.ayahs) { ayah in
                VStack(spacing: 0) {
                    AyahRowView(
                        ayah: ayah,
                        surahNumber: surah.id,
                        surahName: surah.englishName,
                        isBookmarked: quranVM.isBookmarked(surah: surah.id, ayah: ayah.numberInSurah),
                        isSelected: selectedAyahId == ayah.id,
                        isCurrentlyPlaying: audioPlayer.isPlaying && audioPlayer.currentGlobalAyah == ayah.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAyahId = selectedAyahId == ayah.id ? nil : ayah.id
                            }
                        },
                        onBookmark: {
                            quranVM.toggleBookmark(surah: surah.id, ayah: ayah, surahName: surah.englishName)
                            hapticTrigger += 1
                        },
                        onAskAI: {
                            aiContextText = "Explain this ayah from \(surah.englishName), Ayah \(ayah.numberInSurah):\n\n\(ayah.arabicText)\n\n\"\(ayah.translation)\""
                            showAIForAyah = true
                        },
                        onPlayFromHere: {
                            audioPlayer.playFromAyah(ayah, surahNumber: surah.id, reciter: audioPlayer.selectedReciter, ayahs: quranVM.ayahs)
                            hapticTrigger += 1
                        }
                    )
                    .id(ayah.id)

                    Divider()
                        .padding(.horizontal, 20)
                }
            }
        }
    }

    private var audioPlayerBar: some View {
        VStack(spacing: 0) {
            if let error = audioPlayer.errorMessage {
                HStack(spacing: 8) {
                    Text(error)
                        .font(.system(.caption))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                    Button(NafsStrings.retry.localized) {
                        audioPlayer.playSurah(surahNumber: surah.id, reciter: audioPlayer.selectedReciter, ayahs: quranVM.ayahs)
                    }
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }

            HStack(spacing: 20) {
                Button {
                    audioPlayer.playPrevious()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.text)
                }

                Button {
                    if audioPlayer.isLoading {
                        return
                    }
                    if !audioPlayer.isPlaying && !audioPlayer.hasLoadedAudio {
                        audioPlayer.playSurah(surahNumber: surah.id, reciter: audioPlayer.selectedReciter, ayahs: quranVM.ayahs)
                    } else {
                        audioPlayer.togglePlayPause()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(NafsTheme.goldGradient)
                            .frame(width: 44, height: 44)
                        if audioPlayer.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(.body, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: audioPlayer.isPlaying)

                Button {
                    audioPlayer.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.text)
                }

                Spacer()

                Button {
                    audioPlayer.isRepeatEnabled.toggle()
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(.body))
                        .foregroundStyle(audioPlayer.isRepeatEnabled ? NafsTheme.gold : NafsTheme.subtleText)
                }
            }
            .padding(.horizontal, 20)

            Text(audioPlayer.selectedReciter.displayName)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
                .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .background(
            NafsTheme.card
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
    }
}

private struct AyahRowView: View {
    let ayah: QuranAyah
    let surahNumber: Int
    let surahName: String
    let isBookmarked: Bool
    let isSelected: Bool
    let isCurrentlyPlaying: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void
    let onAskAI: () -> Void
    let onPlayFromHere: () -> Void

    private var ayahNumberArabic: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: ayah.numberInSurah)) ?? "\(ayah.numberInSurah)"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                if isCurrentlyPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(.caption2))
                        .foregroundStyle(NafsTheme.gold)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                }

                Spacer()

                Button(action: onBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(.body))
                        .foregroundStyle(isBookmarked ? NafsTheme.gold : NafsTheme.subtleText)
                }
            }

            Button(action: onTap) {
                VStack(spacing: 18) {
                    Text(ayahText)
                        .font(.custom("Geeza Pro", size: 32).weight(.regular))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .lineSpacing(24)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .environment(\.layoutDirection, .rightToLeft)

                    Rectangle()
                        .fill(NafsTheme.gold.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.horizontal, 60)

                    Text(ayah.translation)
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .lineSpacing(6)
                }
            }

            if isSelected {
                HStack(spacing: 10) {
                    Button(action: onPlayFromHere) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(.caption))
                            Text(NafsStrings.playFromAyah.localized)
                                .font(.system(.caption, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(NafsTheme.goldGradient)
                        .clipShape(.capsule)
                    }

                    Button(action: onBookmark) {
                        HStack(spacing: 4) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(.caption))
                            Text(isBookmarked ? NafsStrings.bookmarked.localized : NafsStrings.bookmark.localized)
                                .font(.system(.caption, weight: .medium))
                        }
                        .foregroundStyle(NafsTheme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(NafsTheme.gold.opacity(0.1))
                        .clipShape(.capsule)
                    }

                    Button(action: onAskAI) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(.caption))
                            Text(NafsStrings.askNafsAI.localized)
                                .font(.system(.caption, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(NafsTheme.goldGradient)
                        .clipShape(.capsule)
                    }

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(isCurrentlyPlaying ? NafsTheme.gold.opacity(0.04) : .clear)
    }

    private var ayahText: String {
        // Embed a Quran.com-style ornament + Arabic-Indic number at end of ayah
        let ornamentOpen = "\u{FD3F}"   // ornate right parenthesis
        let ornamentClose = "\u{FD3E}"  // ornate left parenthesis
        return "\(ayah.arabicText) \(ornamentClose)\(ayahNumberArabic)\(ornamentOpen)"
    }
}
