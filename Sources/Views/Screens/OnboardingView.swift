import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            privacyPage.tag(1)
            aiPage.tag(2)
            disclaimerPage.tag(3)
        }
        .tabViewStyle(.automatic)
        #if os(macOS)
        .frame(width: 500, height: 520)
        #endif
    }

    // MARK: - Pages

    private var welcomePage: some View {
        OnboardingPage(
            icon: "book.closed.fill",
            iconColor: .purple,
            title: "Welcome to Kinen",
            subtitle: "記念",
            description: "Your private AI-powered journal.\nReflect, discover patterns, and grow — all on your device.",
            buttonTitle: "Next",
            action: { withAnimation { currentPage = 1 } }
        )
    }

    private var privacyPage: some View {
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .green,
            title: "100% Private",
            subtitle: "Zero cloud. Zero tracking.",
            description: "Every word you write stays on this device.\nNo servers, no accounts, no data collection.\nYour thoughts belong to you alone.",
            buttonTitle: "Next",
            action: { withAnimation { currentPage = 2 } }
        )
    }

    private var aiPage: some View {
        OnboardingPage(
            icon: "brain.head.profile.fill",
            iconColor: .purple,
            title: "AI That Understands You",
            subtitle: "On-device intelligence",
            description: "Mood analysis, pattern discovery, and CBT-based reflections — all powered by on-device AI.\nNo internet required. No API calls.",
            buttonTitle: "Next",
            action: { withAnimation { currentPage = 3 } }
        )
    }

    private var disclaimerPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Important Note")
                .font(.title)
                .fontWeight(.bold)

            Text("Kinen is a **self-reflection and journaling tool**.\n\nIt is **not** a substitute for professional mental health care, therapy, or crisis intervention.\n\nIf you're experiencing a mental health crisis, please reach out to a professional or call your local crisis line.")
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
                Text("I Understand — Start Journaling")
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
