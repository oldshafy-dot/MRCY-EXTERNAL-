import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: PatchProjectStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var licenseSession: LicenseSessionController
    @EnvironmentObject private var contentUpdates: ContentUpdateController
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @StateObject private var controller = VitaPatchController()
    @State private var tab: VitaTab = .home
    @State private var selectedGame: VitaGame?
    @State private var pendingPatchID: UUID?
    @State private var pendingOpen: Bool?

    private var busy: Bool { store.isBusy || controller.isWorking }
    private var items: [PatchLibraryItem] { store.items }

    private func items(for game: VitaGame) -> [PatchLibraryItem] {
        items
            .filter { item in
                ContentFunctionMetadataStore.metadata(for: item.id)?.gameSlug ?? "free-fire"
                    == game.slug
            }
            .sorted { left, right in
                let leftSort = ContentFunctionMetadataStore.metadata(for: left.id)?.sort ?? .max
                let rightSort = ContentFunctionMetadataStore.metadata(for: right.id)?.sort ?? .max
                if leftSort != rightSort { return leftSort < rightSort }
                return BundledFunctionCatalog.displayName(for: left)
                    .localizedCaseInsensitiveCompare(
                        BundledFunctionCatalog.displayName(for: right)
                    ) == .orderedAscending
            }
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            pageScroll(homeGamesPage)
                .opacity(tab == .home && selectedGame == nil ? 1 : 0)
                .allowsHitTesting(tab == .home && selectedGame == nil)
                .accessibilityHidden(tab != .home || selectedGame != nil)
                .transaction { $0.animation = nil }

            if let game = selectedGame {
                pageScroll(gameFunctionsPage(game))
                    .opacity(tab == .home ? 1 : 0)
                    .allowsHitTesting(tab == .home)
                    .accessibilityHidden(tab != .home)
            }

            pageScroll(profilePage)
                .opacity(tab == .profile ? 1 : 0)
                .allowsHitTesting(tab == .profile)
                .accessibilityHidden(tab != .profile)

            pageScroll(infoPage)
                .opacity(tab == .info ? 1 : 0)
                .allowsHitTesting(tab == .info)
                .accessibilityHidden(tab != .info)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selectedGame == nil {
                VitaLiquidTabBar(selection: $tab)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
        .alert(
            "ROBO iOS",
            isPresented: Binding(
                get: { controller.message != nil },
                set: { if !$0 { controller.message = nil } }
            )
        ) {
            Button("OK", role: .cancel) { controller.message = nil }
        } message: {
            Text(controller.message ?? "")
        }
        .onAppear {
            if contentUpdates.integrityCompromised {
                RuntimeGuard.rejectTamper()
            }
            controller.licenseAllowsApply = { licenseSession.hasLiveAuthority && contentUpdates.hasVerifiedPolicy && contentUpdates.requiredRelease == nil }
            controller.requestPermit = { packageID, packageData, apply in
                try await licenseSession.authorizeWrite(
                    packageID: packageID,
                    packageData: packageData,
                    apply: apply
                )
            }
            controller.refresh(items: items)
            restoreLeftoverPatchesIfNeeded()
            scheduleBackgroundMusic(true)
        }
        .onDisappear {
            VitaBackgroundMusic.setPlaying(false)
        }
        .onChange(of: tab) { value in
            if value != .home {
                selectedGame = nil
            }
        }
        .onChange(of: store.isBusy) { value in
            if !value {
                controller.refresh(items: items)
                restoreLeftoverPatchesIfNeeded()
            }
        }
        .onChange(of: appState.exploitStatus) { handlePreparationChange($0) }
        .onChange(of: scenePhase) { phase in
            scheduleBackgroundMusic(phase == .active)
            guard phase == .active else { return }
            Task { await contentUpdates.checkForUpdates(session: licenseSession, store: store) }
        }
        .task { await contentUpdates.checkForUpdates(session: licenseSession, store: store) }
    }

    private func pageScroll<Content: View>(_ content: Content) -> some View {
        ScrollView {
            content
                .frame(maxWidth: 560)
                .padding(.horizontal, AppTheme.pagePadding)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private var homeGamesPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            // New Banner Design
            ZStack(alignment: .bottomLeading) {
                // Background Image/Gradient placeholder
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.05, green: 0.1, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // "LIVE" Badge
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.leading, 16)
                    Spacer()
                }

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("ROBOT EXTERNAL")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("PLAY SMARTER")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .padding(.bottom, 20)
                .padding(.leading, 16)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Game Selector (Pill Buttons)
            HStack(spacing: 12) {
                ForEach(VitaGame.allCases) { game in
                    Button {
                        selectedGame = game
                    } label: {
                        Text(game.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(selectedGame == game ? Color.white : AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Group {
                                    if selectedGame == game {
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        AppTheme.card
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Function Section Header
            Text("FUNCTION")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(AppTheme.accent)
                .padding(.top, 8)

            // Function List
            if let game = selectedGame {
                if items(for: game).isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(busy ? "Checking for updates…" : "No functions yet. They will appear after an update.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if busy {
                            ProgressView()
                                .tint(AppTheme.accent)
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(items(for: game)) { item in
                            functionRow(item)
                        }
                    }
                }
            } else {
                // Default to first game if none selected, or show prompt
                if let firstGame = VitaGame.allCases.first {
                    VStack(spacing: 12) {
                        ForEach(items(for: firstGame)) { item in
                            functionRow(item)
                        }
                    }
                }
            }
        }
    }

    private func gameRow(_ game: VitaGame) -> some View {
        Button {
            selectedGame = game
        } label: {
            HStack(spacing: 14) {
                GameIcon(game: game, size: 54)

                VStack(alignment: .leading, spacing: 3) {
                    Text("PLAY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text(game.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text(game.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(game.title). \(game.subtitle)")
        .accessibilityHint("Opens functions for this game")
    }

    private func gameFunctionsPage(_ game: VitaGame) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Button {
                selectedGame = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text(game.title)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to Home")

            HStack(alignment: .center, spacing: 16) {
                GameIcon(game: game, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.eyebrow)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text(game.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("PLAY BEYOND LIMITS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }

            if items(for: game).isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(busy ? "Checking for updates…" : "No functions yet. They will appear after an update.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    if busy {
                        ProgressView()
                            .tint(AppTheme.accent)
                    }
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(items(for: game)) { item in
                        functionRow(item)
                    }
                }
            }
        }
    }

    private var titleWordmark: some View {
        VitaTitleWordmark(maxWidth: 188, alignment: .leading)
    }

    private func functionRow(_ item: PatchLibraryItem) -> some View {
        let open = controller.isOpen(item)
        let waiting = pendingPatchID == item.id && pendingOpen != nil
        let metadata = ContentFunctionMetadataStore.metadata(for: item.id)
        let name = BundledFunctionCatalog.displayName(for: item)
        let description = metadata?.description.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        let glyph = FunctionGlyph.symbol(icon: metadata?.icon, name: name)

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.15))
                Image(systemName: glyph)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if waiting {
                    Text("Preparing device…")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { open },
                set: { requestOpen($0, item: item) }
            ))
            .labelsHidden()
            .tint(AppTheme.accent)
            .disabled(
                busy
                    || item.project == nil
                    || !appState.isSupported
                    || appState.kernelExploitRunning
                    || waiting
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue(open ? "Open" : "Closed")
        .accessibilityHint(description)
    }

    private var profilePage: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                AppLogo(size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text("ROBO iOS")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("Play Beyond Limits")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer(minLength: 0)
            }

            profileSection("Device") {
                VitaProfileRow(
                    icon: "iphone",
                    title: "This iPhone",
                    subtitle: appState.isSupported
                        ? "Ready to use functions"
                        : "This iOS version is not supported",
                    badge: appState.isSupported ? "Supported" : "Unsupported",
                    badgeColor: compatibilityTint
                )
                VitaProfileRow(
                    icon: "iphone",
                    title: "Model",
                    value: AppInfo.hardwareDisplayName
                )
                VitaProfileRow(
                    icon: "cpu",
                    title: "iOS Version",
                    value: AppInfo.osVersion
                )
                VitaProfileRow(
                    icon: "square.stack.3d.up.fill",
                    title: "Build",
                    value: AppInfo.osBuild
                )
            }

            profileSection("License") {
                VitaProfileRow(
                    icon: "calendar",
                    title: "Expiry",
                    value: licenseSession.profile?.expiryText ?? "—"
                )
            }

            profileSection("App") {
                VitaProfileRow(
                    icon: "info.circle.fill",
                    title: "Name",
                    value: "ROBO iOS"
                )
                VitaProfileRow(
                    icon: "square.stack.3d.up.fill",
                    title: "Version",
                    value: appVersion
                )
            }

            Button {
                licenseSession.logout()
            } label: {
                HStack(spacing: 12) {
                    VitaProfileIcon(systemName: "rectangle.portrait.and.arrow.right", tint: .red)
                    Text("Sign Out")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.red)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(minHeight: 56)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sign Out")
        }
    }

    private func profileSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VitaSectionHeader(title: title)
            VitaProfileCard(content: content)
        }
    }

    private var infoPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                AppLogo(size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text("ROBO iOS")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("PLAY BEYOND LIMITS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                VitaSectionHeader(title: "Contact")
                VitaProfileCard {
                    infoLinkRow(
                        title: "Telegram",
                        subtitle: "Join our Telegram",
                        icon: "paperplane.fill",
                        url: "https://t.me/VITA_1280"
                    )
                    infoLinkRow(
                        title: "Channel",
                        subtitle: "Latest news & updates",
                        icon: "speaker.wave.2.fill",
                        url: "https://t.me/vitamodvip"
                    )
                    infoLinkRow(
                        title: "Website",
                        subtitle: "Visit our website",
                        icon: "globe",
                        url: "https://vitamods.com"
                    )
                    infoLinkRow(
                        title: "បុកពេជ្យតាម ID",
                        subtitle: "Get your key now",
                        icon: "cart.fill",
                        url: "https://t.me/maslowkhtopup",
                        hiddenURL: "https://maslowkh-topup.com/"
                    )
                    infoLinkRow(
                        title: "ទិញ Mod តាម Bot",
                        subtitle: "Buy mods via Telegram bot",
                        icon: "bubble.left.and.bubble.right.fill",
                        url: "https://t.me/Dns_ff_bot"
                    )
                }
            }
        }
    }

    private func infoLinkRow(
        title: String,
        subtitle: String,
        icon: String,
        url: String,
        hiddenURL: String? = nil
    ) -> some View {
        Button {
            if let destination = URL(string: url) {
                openURL(destination)
            }
        } label: {
            HStack(spacing: 12) {
                VitaProfileIcon(systemName: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            guard let hiddenURL, let destination = URL(string: hiddenURL) else { return }
            openURL(destination)
        }
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private var compatibilityTint: Color {
        appState.isSupported ? Color(red: 0.22, green: 0.86, blue: 0.48) : .red
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var canAccessPatchedFiles: Bool {
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17 {
            return false
        }
        if appState.kernelExploitApplicable {
            return appState.exploitStatus.isSuccess
        }
        return appState.isSupported
    }

    private func restoreLeftoverPatchesIfNeeded() {
        controller.restoreLeftoversIfNeeded(
            items: items,
            canAccessFiles: canAccessPatchedFiles
        )
    }

    private func scheduleBackgroundMusic(_ playing: Bool) {
        if !playing || ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 17 {
            VitaBackgroundMusic.setPlaying(playing)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            VitaBackgroundMusic.setPlaying(true)
        }
    }

    private func requestOpen(_ open: Bool, item: PatchLibraryItem) {
        guard licenseSession.hasLiveAuthority && contentUpdates.hasVerifiedPolicy && contentUpdates.requiredRelease == nil else {
            controller.message = "License required."
            return
        }
        if appState.kernelExploitApplicable && !appState.exploitStatus.isSuccess {
            pendingPatchID = item.id
            pendingOpen = open
            appState.runKernelExploitIfNeeded()
            return
        }
        controller.setOpen(open, item: item, items: items)
    }

    private func handlePreparationChange(_ status: ExploitStatus) {
        if status.isSuccess {
            controller.restoreLeftoversIfNeeded(
                items: items,
                canAccessFiles: true
            ) {
                applyPendingOpenIfNeeded()
            }
        } else if status.isFailed, pendingOpen != nil {
            pendingPatchID = nil
            pendingOpen = nil
            controller.message = "Device preparation failed. Restart the app and try again."
        }
    }

    private func applyPendingOpenIfNeeded() {
        guard let pendingOpen,
              let pendingPatchID,
              let item = items.first(where: { $0.id == pendingPatchID }) else { return }
        self.pendingPatchID = nil
        self.pendingOpen = nil
        controller.setOpen(pendingOpen, item: item, items: items)
    }
}
