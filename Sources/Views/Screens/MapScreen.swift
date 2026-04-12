import SwiftUI
import SwiftData
import MapKit

/// Map view showing all geotagged journal entries.
struct MapScreen: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var selectedEntry: JournalEntry?
    @State private var position: MapCameraPosition = .automatic

    private var geotaggedEntries: [JournalEntry] {
        entries.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $position, selection: $selectedEntry) {
                    ForEach(geotaggedEntries) { entry in
                        Annotation(
                            entry.displayTitle,
                            coordinate: CLLocationCoordinate2D(
                                latitude: entry.latitude!,
                                longitude: entry.longitude!
                            ),
                            anchor: .bottom
                        ) {
                            mapPin(for: entry)
                        }
                        .tag(entry)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }

                // Entry count badge
                VStack {
                    HStack {
                        Spacer()
                        Text(String(format: String(localized: "map.entryCount.%lld"), geotaggedEntries.count))
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding()
                    }
                    Spacer()
                }

                // Selected entry card
                if let entry = selectedEntry {
                    NavigationLink(value: entry) {
                        HStack(spacing: 12) {
                            if let mood = entry.mood {
                                Text(mood.emoji).font(.title2)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayTitle)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(entry.preview)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                HStack(spacing: 8) {
                                    if let location = entry.location {
                                        Label(location, systemImage: "location.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                    Text(entry.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(String(localized: "map.title"))
            .navigationDestination(for: JournalEntry.self) { entry in
                EntryDetailScreen(entry: entry)
            }
            .overlay {
                if geotaggedEntries.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "map.empty.title"), systemImage: "map")
                    } description: {
                        Text(String(localized: "map.empty.description"))
                    }
                }
            }
        }
    }

    private func mapPin(for entry: JournalEntry) -> some View {
        VStack(spacing: 0) {
            Text(entry.mood?.emoji ?? "📍")
                .font(.title3)
                .padding(6)
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(radius: 2)
                )
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
    }
}
