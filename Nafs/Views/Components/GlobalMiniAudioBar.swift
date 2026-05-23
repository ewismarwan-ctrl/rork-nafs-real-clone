import SwiftUI
import UIKit

struct GlobalMiniAudioBar: View {
    let audioPlayer: QuranAudioPlayer
    var storeViewModel: StoreViewModel? = nil
    @State private var showReciterPicker: Bool = false

    private var title: String {
        let (surah, ayah) = SurahInfo.surahAndAyah(fromGlobal: audioPlayer.currentGlobalAyah)
        let name = SurahInfo.all.first(where: { $0.id == surah })?.englishName ?? "Surah \(surah)"
        return "\(name) · Ayah \(ayah)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showReciterPicker = true
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(NafsTheme.gold.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                            .lineLimit(1)
                        HStack(spacing: 3) {
                            Text(audioPlayer.selectedReciter.displayName)
                                .font(.system(.caption2))
                                .foregroundStyle(NafsTheme.subtleText)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(NafsTheme.gold)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 2)

            Button {
                audioPlayer.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Previous ayah")

            Button {
                if !audioPlayer.isLoading {
                    audioPlayer.togglePlayPause()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(NafsTheme.goldGradient)
                        .frame(width: 36, height: 36)
                    if audioPlayer.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(.footnote, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }

            Button {
                audioPlayer.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Next ayah")

            Button {
                audioPlayer.isRepeatEnabled.toggle()
            } label: {
                Image(systemName: audioPlayer.isRepeatEnabled ? "repeat.1" : "repeat")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(audioPlayer.isRepeatEnabled ? NafsTheme.gold : NafsTheme.subtleText)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Repeat verse")

            Button {
                audioPlayer.stop(clearState: true)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
                    .frame(width: 26, height: 26)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NafsTheme.card)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 0.5)
        )
        .onChange(of: audioPlayer.isPlaying) { _, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onChange(of: audioPlayer.hasLoadedAudio) { _, newValue in
            if !newValue { UIApplication.shared.isIdleTimerDisabled = false }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(isPresented: $showReciterPicker) {
            if let storeViewModel {
                ReciterPickerSheet(audioPlayer: audioPlayer, storeViewModel: storeViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
