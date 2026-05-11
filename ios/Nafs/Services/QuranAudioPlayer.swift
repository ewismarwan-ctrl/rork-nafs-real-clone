import SwiftUI
import AVFoundation
import MediaPlayer
import Combine

@Observable
@MainActor
class QuranAudioPlayer {
    var isPlaying: Bool = false
    var isLoading: Bool = false
    var currentSurah: Int = 0
    var currentAyahIndex: Int = 0
    var selectedReciter: QuranReciter = .alafasy
    var errorMessage: String? = nil
    var isRepeatEnabled: Bool = false
    var hasLoadedAudio: Bool = false
    var currentGlobalAyah: Int = 0

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: Any?
    private var ayahList: [QuranAyah] = []
    private var preloadedItem: AVPlayerItem?
    private var preloadedGlobalAyah: Int = 0

    init() {
        loadSavedReciter()
        setupRemoteTransportControls()
    }

    func playSurah(surahNumber: Int, reciter: QuranReciter, ayahs: [QuranAyah] = [], startFromAyah: QuranAyah? = nil) {
        currentSurah = surahNumber
        selectedReciter = reciter
        ayahList = ayahs

        if let startAyah = startFromAyah {
            currentAyahIndex = ayahs.firstIndex(where: { $0.id == startAyah.id }) ?? 0
            playGlobalAyah(startAyah.id)
        } else if let first = ayahs.first {
            currentAyahIndex = 0
            playGlobalAyah(first.id)
        } else {
            let offset = SurahInfo.ayahOffsets[surahNumber - 1]
            playGlobalAyah(offset + 1)
        }
    }

    func playFromAyah(_ ayah: QuranAyah, surahNumber: Int, reciter: QuranReciter, ayahs: [QuranAyah]) {
        currentSurah = surahNumber
        selectedReciter = reciter
        ayahList = ayahs
        currentAyahIndex = ayahs.firstIndex(where: { $0.id == ayah.id }) ?? 0
        playGlobalAyah(ayah.id)
    }

    private func activateAudioSessionIfNeeded() {
        // Lazily activate the audio session right before playback. We avoid
        // activating at app launch because that can crash on TestFlight.
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
    }

    private func playGlobalAyah(_ globalNumber: Int) {
        activateAudioSessionIfNeeded()
        isLoading = true
        isPlaying = false
        errorMessage = nil
        currentGlobalAyah = globalNumber
        hasLoadedAudio = true

        let (surah, ayah) = SurahInfo.surahAndAyah(fromGlobal: globalNumber)
        let surahStr = String(format: "%03d", surah)
        let ayahStr = String(format: "%03d", ayah)
        let urlString = "https://everyayah.com/data/\(selectedReciter.everyAyahFolder)/\(surahStr)\(ayahStr).mp3"

        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }

        cleanupPlayer()

        let item = AVPlayerItem(url: url)
        playerItem = item
        player = AVPlayer(playerItem: item)

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observedItem, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch observedItem.status {
                case .readyToPlay:
                    self.player?.play()
                    self.isPlaying = true
                    self.isLoading = false
                    self.updateNowPlayingInfo()
                    self.preloadNextAyah()
                case .failed:
                    self.isLoading = false
                    self.errorMessage = L10n.text("Could not load audio. Check your connection.", "تعذر تحميل الصوت. تحقق من اتصالك.")
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isRepeatEnabled {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                } else {
                    self.advanceToNextAyah()
                }
            }
        }
    }

    private func advanceToNextAyah() {
        guard !ayahList.isEmpty else {
            isPlaying = false
            updateNowPlayingInfo()
            return
        }
        let nextIndex = currentAyahIndex + 1
        if nextIndex < ayahList.count {
            currentAyahIndex = nextIndex
            let nextId = ayahList[nextIndex].id
            if let preloaded = preloadedItem, preloadedGlobalAyah == nextId {
                playPreloadedItem(preloaded, globalNumber: nextId)
            } else {
                playGlobalAyah(nextId)
            }
        } else {
            isPlaying = false
            updateNowPlayingInfo()
        }
    }

    private func preloadNextAyah() {
        guard !ayahList.isEmpty else { return }
        let nextIndex = currentAyahIndex + 1
        guard nextIndex < ayahList.count else {
            preloadedItem = nil
            preloadedGlobalAyah = 0
            return
        }
        let nextId = ayahList[nextIndex].id
        if preloadedGlobalAyah == nextId, preloadedItem != nil { return }

        let (surah, ayah) = SurahInfo.surahAndAyah(fromGlobal: nextId)
        let surahStr = String(format: "%03d", surah)
        let ayahStr = String(format: "%03d", ayah)
        let urlString = "https://everyayah.com/data/\(selectedReciter.everyAyahFolder)/\(surahStr)\(ayahStr).mp3"
        guard let url = URL(string: urlString) else { return }
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable", "duration"])
        item.preferredForwardBufferDuration = 4
        preloadedItem = item
        preloadedGlobalAyah = nextId
    }

    private func playPreloadedItem(_ item: AVPlayerItem, globalNumber: Int) {
        isLoading = false
        errorMessage = nil
        currentGlobalAyah = globalNumber
        hasLoadedAudio = true

        cleanupPlayer()
        preloadedItem = nil
        preloadedGlobalAyah = 0

        playerItem = item
        player = AVPlayer(playerItem: item)
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observedItem, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if observedItem.status == .readyToPlay {
                    self.preloadNextAyah()
                } else if observedItem.status == .failed {
                    self.errorMessage = L10n.text("Could not load audio. Check your connection.", "تعذر تحميل الصوت. تحقق من اتصالك.")
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isRepeatEnabled {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                } else {
                    self.advanceToNextAyah()
                }
            }
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func stop(clearState: Bool = true) {
        cleanupPlayer()
        isPlaying = false
        isLoading = false
        if clearState {
            hasLoadedAudio = false
            errorMessage = nil
            ayahList = []
            currentAyahIndex = 0
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func playNext() {
        if !ayahList.isEmpty {
            advanceToNextAyah()
        } else {
            let next = min(currentSurah + 1, 114)
            currentSurah = next
            let offset = SurahInfo.ayahOffsets[next - 1]
            playGlobalAyah(offset + 1)
        }
    }

    func playPrevious() {
        if !ayahList.isEmpty && currentAyahIndex > 0 {
            currentAyahIndex -= 1
            playGlobalAyah(ayahList[currentAyahIndex].id)
        } else {
            let prev = max(currentSurah - 1, 1)
            currentSurah = prev
            let offset = SurahInfo.ayahOffsets[prev - 1]
            playGlobalAyah(offset + 1)
        }
    }

    func saveReciter(_ reciter: QuranReciter) {
        let changed = selectedReciter != reciter
        selectedReciter = reciter
        UserDefaults.standard.set(reciter.rawValue, forKey: "nafs_selectedReciter")
        if changed {
            preloadedItem = nil
            preloadedGlobalAyah = 0
            if hasLoadedAudio && !ayahList.isEmpty {
                let current = ayahList[currentAyahIndex].id
                playGlobalAyah(current)
            }
        }
    }

    private func loadSavedReciter() {
        if let saved = UserDefaults.standard.string(forKey: "nafs_selectedReciter") {
            if let reciter = QuranReciter(rawValue: saved) {
                selectedReciter = reciter
            } else {
                let migrated = Self.migrateOldReciterValue(saved)
                selectedReciter = migrated
                UserDefaults.standard.set(migrated.rawValue, forKey: "nafs_selectedReciter")
            }
        }
    }

    private static func migrateOldReciterValue(_ old: String) -> QuranReciter {
        switch old {
        case "ar.alafasy": return .alafasy
        case "ar.mahermuaiqly": return .maher
        case "ar.husary": return .husary
        case "ar.minshawi": return .minshawi
        case "ar.abdurrahmaansudais": return .sudais
        case "ar.muhammadayyoub": return .ayoub
        case "ar.abdulbasitmurattal": return .abdulbasit
        default: return .alafasy
        }
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isPlaying else { return }
                self.player?.play()
                self.isPlaying = true
                self.updateNowPlayingInfo()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isPlaying else { return }
                self.player?.pause()
                self.isPlaying = false
                self.updateNowPlayingInfo()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playNext()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playPrevious()
            }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        let (surah, ayah) = SurahInfo.surahAndAyah(fromGlobal: currentGlobalAyah)
        let surahName = SurahInfo.all.first(where: { $0.id == surah })?.englishName ?? "Surah \(surah)"

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "\(surahName) - Ayah \(ayah)",
            MPMediaItemPropertyArtist: selectedReciter.displayName,
            MPMediaItemPropertyAlbumTitle: "Quran",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let duration = playerItem?.duration, duration.isNumeric {
            info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(duration)
        }
        if let currentTime = player?.currentTime(), currentTime.isNumeric {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(currentTime)
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func cleanupPlayer() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()
        player = nil
        playerItem = nil
    }
}
