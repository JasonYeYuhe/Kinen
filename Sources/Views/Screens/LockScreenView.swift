import SwiftUI

struct LockScreenView: View {
    @State private var appLock = AppLockService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("Kinen is Locked")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your journal is protected")
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
