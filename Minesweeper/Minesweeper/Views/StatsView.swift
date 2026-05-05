import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDifficulty = "easy"
    @State private var records: [GameRecord] = []
    @State private var showClearConfirmation = false

    private let difficulties = ["easy", "medium", "hard", "extreme", "custom"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                difficultyPicker

                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        statsSection
                        historySection
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !records.isEmpty {
                        Button("Clear", role: .destructive) {
                            showClearConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog("Clear all \(selectedDifficulty) stats?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    clearRecords()
                }
            }
            .onAppear { fetchRecords() }
            .onChange(of: selectedDifficulty) { _, _ in fetchRecords() }
        }
    }

    private var difficultyPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(difficulties, id: \.self) { diff in
                    Button {
                        selectedDifficulty = diff
                    } label: {
                        Text(diff.capitalized)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedDifficulty == diff
                                    ? Color.accentColor
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                selectedDifficulty == diff ? .white : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No games played yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Play some \(selectedDifficulty) games to see stats here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    private var statsSection: some View {
        Section("Overview") {
            StatRow(label: "Games Played", value: "\(records.count)")
            StatRow(label: "Wins", value: "\(wins.count)")
            StatRow(label: "Win Rate", value: String(format: "%.0f%%", winRate))
            if let best = bestTime {
                StatRow(label: "Best Time", value: formatTime(best))
            }
            if let avg = averageTime {
                StatRow(label: "Avg Win Time", value: formatTime(avg))
            }
        }
    }

    private var historySection: some View {
        Section("History") {
            ForEach(records) { record in
                HStack {
                    Image(systemName: record.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(record.won ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatTime(record.duration))
                            .font(.subheadline.weight(.medium))
                        Text(record.date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(record.rows)x\(record.cols)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Data

    private var wins: [GameRecord] { records.filter(\.won) }

    private var winRate: Double {
        guard !records.isEmpty else { return 0 }
        return Double(wins.count) / Double(records.count) * 100
    }

    private var bestTime: TimeInterval? {
        wins.map(\.duration).min()
    }

    private var averageTime: TimeInterval? {
        guard !wins.isEmpty else { return nil }
        return wins.map(\.duration).reduce(0, +) / Double(wins.count)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }

    private func fetchRecords() {
        let difficulty = selectedDifficulty
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.difficulty == difficulty },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        records = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func clearRecords() {
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
        records = []
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}
