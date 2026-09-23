import SwiftUI

struct LicenseGateView: View {
    @EnvironmentObject private var session: LicenseSessionController
    @EnvironmentObject private var updates: ContentUpdateController
    @EnvironmentObject private var store: PatchProjectStore

    var body: some View {
        Group {
            switch session.state {
            case .loading:
                AppLaunchLoadingView()
            case .unconfigured:
                if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17 {
                    LicenseActivationView()
                } else {
                    Color.clear.onAppear { RuntimeGuard.seal() }
                }
            case .signedOut:
                LicenseActivationView()
            case .authenticated:
                if session.hasLiveAuthority {
                    authenticatedRoot
                } else if updates.integrityCompromised {
                    Color.clear.onAppear { RuntimeGuard.rejectTamper() }
                } else {
                    AppLaunchLoadingView()
                }
            case .blocked(let message):
                LicenseBlockedView(message: message)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await session.startIfNeeded()
            await session.renewAuthorityIfNeeded()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                await session.renewAuthorityIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var authenticatedRoot: some View {
        if let release = updates.requiredRelease {
            RequiredContentUpdateView(release: release)
        } else if updates.integrityCompromised {
            Color.clear.onAppear { RuntimeGuard.rejectTamper() }
        } else if updates.hasVerifiedPolicy {
            ContentView()
        } else {
            ContentPolicyVerificationView()
        }
    }

}

private struct ContentPolicyVerificationView: View {
    @EnvironmentObject private var session: LicenseSessionController
    @EnvironmentObject private var updates: ContentUpdateController
    @EnvironmentObject private var store: PatchProjectStore

    var body: some View {
        ZStack {
            AppLaunchLoadingView()
            if let error = updates.errorMessage, !updates.isChecking {
                VStack(spacing: 14) {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await updates.checkForUpdates(
                                session: session,
                                store: store
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(updates.isChecking)
                }
                .padding(28)
            }
        }
        .task {
            await updates.checkForUpdates(session: session, store: store)
        }
    }
}

private struct AppLaunchLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                wordmark
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(AppTheme.accent)
                        .scaleEffect(1.15)
                    Text("Loading..")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 36)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading")
    }

    private var wordmark: some View {
        VitaTitleWordmark(maxWidth: 240)
    }
}

struct LicenseActivationView: View {
    @EnvironmentObject private var session: LicenseSessionController
    @State private var licenseKey = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 36)
                        header
                        form
                            .padding(.top, 36)
                        if let error = session.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 18)
                                .accessibilityLabel("Activation error. \(error)")
                        }
                        Spacer(minLength: 36)
                    }
                    .padding(.horizontal, 28)
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .tint(AppTheme.accent)
    }

    private var header: some View {
        VStack(spacing: 14) {
            AppLogo(size: 78)
                .shadow(color: AppTheme.accent.opacity(0.45), radius: 22, y: 0)
                .padding(.bottom, 18)

            Text("ACTIVATION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(AppTheme.tertiaryText)

            (Text("Vita Mod ") + Text("Vip").foregroundColor(AppTheme.accent))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.white)

            Text("Enter your license key to activate this device.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LICENSE KEY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.tertiaryText)

            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.tertiaryText)
                    .accessibilityHidden(true)

                SecureField("Enter license key", text: $licenseKey)
                    .textContentType(.password)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white)
                    .disabled(session.isWorking)
                    .accessibilityLabel("License key")
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(Color.white.opacity(0.06), in: Capsule())

            Button {
                Task {
                    await session.beginActivation(licenseKey: licenseKey)
                    if session.state == .authenticated {
                        licenseKey = ""
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if session.isWorking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "key.fill")
                    }
                    Text(session.isWorking ? "Activating…" : "Activate")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.72, blue: 1.00),
                            Color(red: 0.10, green: 0.42, blue: 1.00)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(session.isWorking || licenseKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty)
            .opacity(
                licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? 0.55
                    : 1
            )
            .padding(.top, 10)
        }
    }
}

struct LicenseConfigurationView: View {
    let message: String

    var body: some View {
        LicenseMessagePage<EmptyView>(
            icon: "gear.badge.xmark",
            title: "Licensing not configured",
            message: message,
            detail: "Access remains locked until a valid HTTPS server and Ed25519 key are configured."
        )
    }
}

struct LicenseBlockedView: View {
    @EnvironmentObject private var session: LicenseSessionController
    let message: String

    var body: some View {
        LicenseMessagePage(
            icon: "wifi.exclamationmark",
            title: "License unavailable",
            message: message,
            detail: "The app is locked because the session could not be securely validated."
        ) {
            Button("Retry") {
                Task { await session.retrySession() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(session.isWorking)

            Button("Log out", role: .destructive) {
                session.logout()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct LicenseMessagePage<Actions: View>: View {
    let icon: String
    let title: String
    let message: String
    let detail: String
    let actions: Actions

    init(
        icon: String,
        title: String,
        message: String,
        detail: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.detail = detail
        self.actions = actions()
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.primaryText)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryText)
                actions
            }
            .multilineTextAlignment(.center)
            .padding(28)
            .frame(maxWidth: 480)
        }
    }
}

private extension LicenseMessagePage where Actions == EmptyView {
    init(icon: String, title: String, message: String, detail: String) {
        self.init(icon: icon, title: title, message: message, detail: detail) {
            EmptyView()
        }
    }
}

struct RequiredContentUpdateView: View {
    @EnvironmentObject private var session: LicenseSessionController
    @EnvironmentObject private var updates: ContentUpdateController
    @EnvironmentObject private var store: PatchProjectStore
    let release: ContentReleaseManifest

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 36) {
                        Spacer(minLength: 48)
                        VitaTitleWordmark(maxWidth: 260)
                        releaseNotes
                        if let error = updates.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("Update error. \(error)")
                        }
                        installButton
                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 430)
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
        .task {
            await updates.checkForUpdates(session: session, store: store)
        }
    }

    private var descriptionLines: [String] {
        let lines = (release.description ?? "")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.isEmpty ? ["Update required before functions can be used."] : lines
    }

    private var releaseNotes: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                VitaProfileIcon(systemName: "doc.fill")
                Text("What's New")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Text("v\(release.version)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
                .padding(.leading, 60)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(descriptionLines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)
                            .accessibilityHidden(true)
                        Text(line)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var installButton: some View {
        Button {
            Task {
                await updates.installRequired(session: session, store: store)
            }
        } label: {
            HStack(spacing: 10) {
                if updates.isInstalling {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.down")
                }
                Text(updates.isInstalling ? "Installing…" : "Download & Install")
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(AppTheme.accent, in: Capsule())
            .shadow(color: AppTheme.accent.opacity(0.45), radius: 18, y: 0)
        }
        .buttonStyle(.plain)
        .disabled(updates.isInstalling)
        .accessibilityHint("Downloads and verifies the required data packages")
    }
}
