import AVFoundation
import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.00, green: 0.72, blue: 1.00)
    static let pageBackground = Color.black
    static let consoleBackground = Color(red: 32 / 255, green: 32 / 255, blue: 32 / 255)
    static let card = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let primaryText = Color.white
    static let secondaryText = Color(red: 152 / 255, green: 152 / 255, blue: 157 / 255)
    static let tertiaryText = Color(red: 99 / 255, green: 99 / 255, blue: 102 / 255)
    static let hairline = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    static let pagePadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    static let rowPadding: CGFloat = 14
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    static let contentCardCornerRadius: CGFloat = 20
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.contentCardCornerRadius,
            style: .continuous
        )
        .strokeBorder(
            Color(uiColor: .separator).opacity(0.22),
            lineWidth: 0.5
        )
        .accessibilityHidden(true)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct VitaTitleWordmark: View {
    var maxWidth: CGFloat = 240
    var alignment: Alignment = .center

    var body: some View {
        Group {
            if let mark = UIImage(named: "TitleWordmark") {
                Image(uiImage: mark)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 8) {
                    (Text("ROBO ") + Text("iOS").foregroundColor(AppTheme.accent))
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color.white)
                    Text("DEV EV SHAFAYAY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .frame(maxWidth: maxWidth, alignment: alignment)
        .accessibilityLabel("ROBO iOS. Play beyond limits.")
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppLogo")
                ?? UIImage(named: "AppIcon")
                ?? UIImage(named: "AppIcon60x60") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "bolt.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}

enum VitaGame: String, CaseIterable, Identifiable, Hashable {
    case freeFire
    case freeFireMax

    var id: String { rawValue }

    var slug: String {
        switch self {
        case .freeFire: return "free-fire"
        case .freeFireMax: return "free-fire-max"
        }
    }

    var title: String {
        switch self {
        case .freeFire: return "Free Fire"
        case .freeFireMax: return "Free Fire MAX"
        }
    }

    var subtitle: String {
        switch self {
        case .freeFire: return "Unlock your potential"
        case .freeFireMax: return "Maximize your experience"
        }
    }

    var eyebrow: String {
        title.uppercased()
    }

    var assetName: String {
        switch self {
        case .freeFire: return "GameIconFreeFire"
        case .freeFireMax: return "GameIconFreeFireMax"
        }
    }
}

enum FunctionGlyph {
    static func symbol(icon: String?, name: String) -> String {
        if let icon, let mapped = symbols[icon] {
            return mapped
        }
        let hay = name.lowercased()
        if hay.contains("aim") { return "scope" }
        if hay.contains("esp") || hay.contains("vision") { return "eye.fill" }
        if hay.contains("recoil") { return "line.3.horizontal" }
        if hay.contains("spread") { return "plus.viewfinder" }
        if hay.contains("reload") || hay.contains("bolt") { return "bolt.fill" }
        if hay.contains("speed") || hay.contains("run") { return "figure.run" }
        if hay.contains("ban") || hay.contains("shield") { return "shield.fill" }
        if hay.contains("shake") || hay.contains("iphone") { return "iphone" }
        return "slider.horizontal.3"
    }

    private static let symbols: [String: String] = [
        "aim": "scope",
        "vision": "eye.fill",
        "recoil": "line.3.horizontal",
        "spread": "plus.viewfinder",
        "reload": "bolt.fill",
        "speed": "figure.run",
        "shield": "shield.fill",
        "device": "iphone",
        "target": "target",
        "radar": "dot.radiowaves.left.and.right",
        "lock": "lock.fill",
        "flame": "flame.fill",
        "spark": "sparkles",
        "hand": "hand.raised.fill",
        "signal": "antenna.radiowaves.left.and.right",
        "slider": "slider.horizontal.3",
    ]
}

struct GameIcon: View {
    let game: VitaGame
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let icon = UIImage(named: game.assetName) {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.card)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}

enum VitaTab: Int, CaseIterable, Hashable {
    case home
    case profile
    case info

    var title: String {
        switch self {
        case .home: return "Home"
        case .profile: return "Profile"
        case .info: return "Info"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .profile: return "person"
        case .info: return "info.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .profile: return "person.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct VitaCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 0.5)
        }
    }
}

struct VitaCardDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.hairline)
            .frame(height: 0.5)
            .padding(.leading, AppTheme.rowPadding)
            .accessibilityHidden(true)
    }
}

struct VitaInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(AppTheme.primaryText)
            Spacer(minLength: 8)
            Text(value)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 14))
        .padding(.horizontal, AppTheme.rowPadding)
        .padding(.vertical, 10)
        .frame(minHeight: 42)
        .accessibilityElement(children: .combine)
    }
}

struct VitaProfileIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.14))
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

struct VitaProfileRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var badge: String? = nil
    var badgeColor: Color = Color(red: 0.22, green: 0.86, blue: 0.48)

    var body: some View {
        HStack(spacing: 12) {
            VitaProfileIcon(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            Spacer(minLength: 8)
            if let badge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(badgeColor.opacity(0.16), in: Capsule())
            } else if let value {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }
}

struct VitaProfileCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }
}

struct VitaSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(AppTheme.secondaryText)
            .padding(.horizontal, 4)
    }
}

struct VitaLiquidTabBar: View {
    @Binding var selection: VitaTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectedTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(VitaTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: 62)
        .frame(maxWidth: 360)
        .background { glassCapsule }
        .frame(maxWidth: .infinity)
    }

    private var glassCapsule: some View {
        Capsule()
            .fill(Color(red: 0.09, green: 0.09, blue: 0.10))
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
    }

    private func tabButton(_ tab: VitaTab) -> some View {
        let selected = selection == tab
        return Button {
            guard selection != tab else { return }
            withAnimation(
                reduceMotion
                    ? .easeOut(duration: 0.15)
                    : .spring(response: 0.36, dampingFraction: 0.86)
            ) {
                selection = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: selected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 17, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selected ? AppTheme.accent : AppTheme.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if selected {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .matchedGeometryEffect(id: "selected-tab", in: selectedTab)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct VitaBannerVideo: UIViewRepresentable, Equatable {
    var isPlaying: Bool

    func makeUIView(context: Context) -> VitaBannerPlayerView {
        let view = VitaBannerPlayerView()
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                view.load()
                view.setPlaying(isPlaying)
            }
        } else {
            view.load()
            view.setPlaying(isPlaying)
        }
        return view
    }

    func updateUIView(_ uiView: VitaBannerPlayerView, context: Context) {
        uiView.setPlaying(isPlaying)
    }
}

final class VitaBannerPlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayerView: AVPlayerLayer { layer as! AVPlayerLayer }
    private var looper: AVPlayerLooper?
    private var player: AVQueuePlayer?
    private var wantsPlayback = false

    func load() {
        guard player == nil,
              let url = Bundle.main.url(forResource: "robo-banner", withExtension: "mp4") else {
            backgroundColor = .black
            return
        }
        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 1
        let queue = AVQueuePlayer(items: [])
        queue.automaticallyWaitsToMinimizeStalling = false
        queue.actionAtItemEnd = .none
        queue.isMuted = true
        queue.volume = 0
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        playerLayerView.player = queue
        playerLayerView.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }

    func setPlaying(_ playing: Bool) {
        guard wantsPlayback != playing else { return }
        wantsPlayback = playing
        if playing {
            playerLayerView.player = player
            player?.isMuted = true
            player?.volume = 0
            player?.play()
        } else {
            player?.isMuted = true
            player?.pause()
        }
    }

    deinit {
        player?.pause()
        player = nil
        looper = nil
    }
}

enum VitaBackgroundMusic {
    private static var player: AVAudioPlayer?

    static func setPlaying(_ playing: Bool) {
        if player == nil { load() }
        if playing {
            activateAudioSession()
            player?.numberOfLoops = -1
            player?.play()
        } else {
            player?.pause()
        }
    }

    private static func load() {
        guard let url = Bundle.main.url(forResource: "song", withExtension: "mp3"),
              let audio = try? AVAudioPlayer(contentsOf: url) else { return }
        audio.numberOfLoops = -1
        audio.prepareToPlay()
        player = audio
    }

    private static func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
