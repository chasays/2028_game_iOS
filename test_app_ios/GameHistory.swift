import Foundation
import CloudKit

struct GameRecord: Codable, Identifiable {
    let id = UUID()
    let score: Int
    let highestTile: Int
    let date: Date
    let moves: Int
    
    init(score: Int, highestTile: Int, moves: Int) {
        self.score = score
        self.highestTile = highestTile
        self.moves = moves
        self.date = Date()
    }
    
    // For CloudKit compatibility
    init(score: Int, highestTile: Int, moves: Int, date: Date) {
        self.score = score
        self.highestTile = highestTile
        self.moves = moves
        self.date = date
    }
}

class GameHistory: ObservableObject {
    @Published var records: [GameRecord] = []
    @Published var isSyncing: Bool = false
    @Published var lastSyncError: String? = nil
    
    private let historyKey = "GameHistoryRecords"
    private let cloudKitContainer = CKContainer.default()
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    private var syncToken: CKServerChangeToken? = nil
    
    init() {
        self.publicDatabase = cloudKitContainer.publicCloudDatabase
        self.privateDatabase = cloudKitContainer.privateCloudDatabase
        loadHistory()
        loadFromCloud()
    }
    
    func addRecord(score: Int, highestTile: Int, moves: Int) {
        let record = GameRecord(score: score, highestTile: highestTile, moves: moves)
        records.append(record)
        saveHistory()
        saveToCloud(record: record)
    }
    
    func clearHistory() {
        records.removeAll()
        saveHistory()
        clearCloudHistory()
    }
    
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(records)
            UserDefaults.standard.set(encoded, forKey: historyKey)
        } catch {
            print("Error encoding game history: \(error.localizedDescription)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        
        do {
            let decoded = try JSONDecoder().decode([GameRecord].self, from: data)
            records = decoded
        } catch {
            print("Error decoding game history: \(error.localizedDescription)")
        }
    }
    
    // MARK: - iCloud Integration
    
    private func saveToCloud(record: GameRecord) {
        // Check if iCloud is available
        cloudKitContainer.accountStatus { (status, error) in
            if error != nil || status != .available {
                DispatchQueue.main.async {
                    self.lastSyncError = "iCloud not available"
                }
                return
            }
            
            let cloudRecord = CKRecord(recordType: "GameRecord")
            cloudRecord["score"] = record.score
            cloudRecord["highestTile"] = record.highestTile
            cloudRecord["moves"] = record.moves
            cloudRecord["date"] = record.date
            
            DispatchQueue.main.async {
                self.isSyncing = true
            }
            
            self.privateDatabase.save(cloudRecord) { (savedRecord, error) in
                DispatchQueue.main.async {
                    self.isSyncing = false
                    if let error = error {
                        self.lastSyncError = "Failed to save to iCloud: \(error.localizedDescription)"
                        print("Error saving to iCloud: \(error.localizedDescription)")
                    } else {
                        self.lastSyncError = nil
                    }
                }
            }
        }
    }
    
    private func loadFromCloud() {
        // Check if iCloud is available
        cloudKitContainer.accountStatus { (status, error) in
            if error != nil || status != .available {
                DispatchQueue.main.async {
                    self.lastSyncError = "iCloud not available"
                }
                return
            }
            
            let query = CKQuery(recordType: "GameRecord", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            DispatchQueue.main.async {
                self.isSyncing = true
            }
            
            self.privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
                DispatchQueue.main.async {
                    self.isSyncing = false
                    if let error = error {
                        self.lastSyncError = "Failed to load from iCloud: \(error.localizedDescription)"
                        print("Error loading from iCloud: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let cloudRecords = records else { return }
                    
                    var newRecords: [GameRecord] = []
                    for cloudRecord in cloudRecords {
                        if let score = cloudRecord["score"] as? Int,
                           let highestTile = cloudRecord["highestTile"] as? Int,
                           let moves = cloudRecord["moves"] as? Int,
                           let date = cloudRecord["date"] as? Date {
                            
                            let record = GameRecord(score: score, highestTile: highestTile, moves: moves, date: date)
                            newRecords.append(record)
                        }
                    }
                    
                    // Merge with existing records, avoiding duplicates
                    let mergedRecords = self.mergeRecords(local: self.records, cloud: newRecords)
                    self.records = mergedRecords
                    self.saveHistory() // Save combined records locally
                    self.lastSyncError = nil
                }
            }
        }
    }
    
    private func mergeRecords(local: [GameRecord], cloud: [GameRecord]) -> [GameRecord] {
        var merged = local
        
        for cloudRecord in cloud {
            // Check if this record already exists locally
            let exists = merged.contains { localRecord in
                return localRecord.score == cloudRecord.score && 
                       localRecord.highestTile == cloudRecord.highestTile && 
                       abs(localRecord.date.timeIntervalSince(cloudRecord.date)) < 60 // Within 1 minute
            }
            
            if !exists {
                merged.append(cloudRecord)
            }
        }
        
        // Sort by date, newest first
        return merged.sorted { $0.date > $1.date }
    }
    
    private func clearCloudHistory() {
        // Check if iCloud is available
        cloudKitContainer.accountStatus { (status, error) in
            if error != nil || status != .available {
                DispatchQueue.main.async {
                    self.lastSyncError = "iCloud not available"
                }
                return
            }
            
            let query = CKQuery(recordType: "GameRecord", predicate: NSPredicate(value: true))
            
            DispatchQueue.main.async {
                self.isSyncing = true
            }
            
            self.privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isSyncing = false
                        self.lastSyncError = "Failed to query records for deletion: \(error.localizedDescription)"
                        print("Error querying records for deletion: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let recordsToDelete = records else { 
                    DispatchQueue.main.async {
                        self.isSyncing = false
                    }
                    return 
                }
                
                let group = DispatchGroup()
                var deletionErrors: [String] = []
                
                for record in recordsToDelete {
                    group.enter()
                    self.privateDatabase.delete(withRecordID: record.recordID) { (_, error) in
                        if let error = error {
                            deletionErrors.append(error.localizedDescription)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.isSyncing = false
                    if !deletionErrors.isEmpty {
                        self.lastSyncError = "Some records failed to delete: \(deletionErrors.joined(separator: ", "))"
                        print("Some iCloud records failed to delete: \(deletionErrors.joined(separator: ", "))")
                    } else {
                        self.lastSyncError = nil
                        print("All iCloud records deleted successfully")
                    }
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func getBestScore() -> Int? {
        return records.max(by: { $0.score < $1.score })?.score
    }
    
    func getAverageScore() -> Double {
        guard !records.isEmpty else { return 0 }
        let totalScore = records.reduce(0) { $0 + $1.score }
        return Double(totalScore) / Double(records.count)
    }
    
    func getTotalGames() -> Int {
        return records.count
    }
}