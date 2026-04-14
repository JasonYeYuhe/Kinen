import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            privacyPage.tag(1)
            aiPage.tag(2)
            syncPage.tag(3)
            disclaimerPage.tag(4)
        }
        .tabViewStyle(.automatic)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 500, minHeight: 420, idealHeight: 520)
        #else
        .presentationDetents([.large])
        #endif
    }

    // MARK: - Pages

    private var welcomePage: some View {
        OnboardingPage(
            icon: "book.closed.fill",
            iconColor: .purple,
            title: String(localized: "onboarding.welcome"),
            subtitle: String(localized: "onboarding.subtitle"),
            description: String(localized: "onboarding.welcome.description"),
            buttonTitle: String(localized: "general.next"),
            action: { withAnimation { currentPage = 1 } }
        )
    }

    private var privacyPage: some View {
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .green,
            title: String(localized: "onboarding.privacy"),
            subtitle: String(localized: "onboarding.privacy.subtitle"),
            description: String(localized: "onboarding.privacy.description"),
            buttonTitle: String(localized: "general.next"),
            action: { withAnimation { currentPage = 2 } }
        )
    }

    private var aiPage: some View {
        OnboardingPage(
            icon: "brain.head.profile.fill",
            iconColor: .purple,
            title: String(localized: "onboarding.ai"),
            subtitle: String(localized: "onboarding.ai.subtitle"),
            description: String(localized: "onboarding.ai.description"),
            buttonTitle: String(localized: "general.next"),
            action: { withAnimation { currentPage = 3 } }
        )
    }

    private var syncPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "icloud.fill")
                .font(.system(size: 48))
                .foregroundStyle(.cyan)

            Text(String(localized: "onboarding.sync"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "onboarding.sync.description"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Toggle(String(localized: "onboarding.sync.toggle"), isOn: $iCloudSyncEnabled)
                .padding(.horizontal, 32)

            Text(String(localized: "onboarding.sync.note"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: { withAnimation { currentPage = 4 } }) {
                Text(String(localized: "general.next"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal, 32)

            Spacer().frame(height: 20)
        }
    }

    private var disclaimerPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(String(localized: "onboarding.disclaimer"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "onboarding.disclaimer.text"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.green)
                Text("988 Suicide & Crisis Lifeline (US): Call or text **988**")
                    .font(.callout)
            }
            .padding()
            .background(.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            Button(action: {
                hasSeenOnboarding = true
            }) {
                Text(String(localized: "onboarding.start"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal, 32)

            Spacer().frame(height: 20)
        }
    }
}

// MARK: - Onboarding Page Template

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(iconColor)

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: action) {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal, 32)

            Spacer().frame(height: 20)
        }
    }
}
