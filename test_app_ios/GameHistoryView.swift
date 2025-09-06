import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var gameHistory: GameHistory
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Statistics section
                if !gameHistory.records.isEmpty {
                    StatisticsView(gameHistory: gameHistory)
                        .padding(.horizontal)
                }
                
                // Sync status
                if gameHistory.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing with iCloud...")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal)
                } else if let error = gameHistory.lastSyncError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // History list
                if gameHistory.records.isEmpty {
                    VStack {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .padding()
                        Text("No game history yet")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(gameHistory.records.sorted(by: { $0.date > $1.date })) { record in
                            GameRecordView(record: record)
                        }
                    }
                }
            }
            .navigationTitle("Game History")
            .navigationBarItems(
                trailing: HStack {
                    Button("Clear") {
                        gameHistory.clearHistory()
                    }
                    .disabled(gameHistory.records.isEmpty)
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var gameHistory: GameHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)
            
            HStack {
                StatisticItem(title: "Total Games", value: "\(gameHistory.getTotalGames())")
                Spacer()
                StatisticItem(title: "Best Score", value: gameHistory.getBestScore() != nil ? "\(gameHistory.getBestScore()!)" : "N/A")
                Spacer()
                StatisticItem(title: "Average", value: String(format: "%.0f", gameHistory.getAverageScore()))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}

struct GameRecordView: View {
    let record: GameRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Score: \(record.score)")
                    .font(.headline)
                Spacer()
                Text("Highest Tile: \(record.highestTile)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Moves: \(record.moves)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(record.date, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}