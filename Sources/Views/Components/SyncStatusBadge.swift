import SwiftUI

struct SyncStatusBadge: View {
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true

    var body: some View {
        HStack(spacing: 4) {
            if iCloudSyncEnabled {
                Image(systemName: "icloud.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "icloud.slash")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .help(iCloudSyncEnabled ? "iCloud Sync enabled" : "iCloud Sync disabled")
    }
}
