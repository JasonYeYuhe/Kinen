import SwiftUI

struct LockScreenView: View {
    @State private var appLock = AppLockService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text(String(localized: "lock.title"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "lock.subtitle"))
                .foregroundStyle(.secondary)

            Button(action: {
                Task { await appLock.unlock() }
            }) {
                Label("Unlock with \(appLock.biometricType.name)", systemImage: appLock.biometricType.icon)
                    .fontWeight(.semibold)
                    .frame(maxWidth: 240)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(appLock.isAuthenticating)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .task {
            // Auto-trigger unlock on appear
            await appLock.unlock()
        }
    }
}
