import Foundation
import SwiftUI

// MARK: - History Entry Model

struct HistoryEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let mode: HistoryMode
    let restaurantName: String?
    let recommendation: RecommendationData
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mode: HistoryMode,
        restaurantName: String?,
        recommendation: RecommendationData
    ) {
        self.id = id
        self.date = date
        self.mode = mode
        self.restaurantName = restaurantName
        self.recommendation = recommendation
    }
}

enum HistoryMode: String, Codable {
    case individual
    case group
}

enum RecommendationData: Codable, Hashable {
    case individual(MenuRecommendation)
    case group(ComboRecommendation)
}

// MARK: - History Store

@Observable
@MainActor
final class HistoryStore {
    private(set) var entries: [HistoryEntry] = []
    
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        self.fileURL = documentsDirectory.appendingPathComponent("history.json")
        self.entries = loadFromDisk()
    }
    
    // MARK: - Public API
    
    func addEntry(mode: AppMode, restaurantName: String?, recommendation: RecommendationData) {
        let entry = HistoryEntry(
            mode: mode == .individual ? .individual : .group,
            restaurantName: restaurantName,
            recommendation: recommendation
        )
        entries.insert(entry, at: 0) // Most recent first
        saveToDisk()
    }
    
    func addIndividualRecommendation(_ recommendation: MenuRecommendation, restaurantName: String?) {
        addEntry(
            mode: .individual,
            restaurantName: restaurantName,
            recommendation: .individual(recommendation)
        )
    }
    
    func addGroupRecommendation(_ recommendation: ComboRecommendation, restaurantName: String?) {
        addEntry(
            mode: .group,
            restaurantName: restaurantName,
            recommendation: .group(recommendation)
        )
    }
    
    func deleteEntry(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveToDisk()
    }
    
    func clearAll() {
        entries = []
        saveToDisk()
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: fileURL)
        } catch {
            print("[HistoryStore] Save failed: \(error)")
        }
    }
    
    private func loadFromDisk() -> [HistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            print("[HistoryStore] Load failed: \(error)")
            return []
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    let store: HistoryStore
    let onSelectEntry: (HistoryEntry) -> Void
    
    @State private var showClearConfirmation = false
    
    var body: some View {
        Group {
            if store.entries.isEmpty {
                emptyStateView
            } else {
                historyListView
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !store.entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        showClearConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog("Clear History?", isPresented: $showClearConfirmation) {
            Button("Clear All", role: .destructive) {
                store.clearAll()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AmbrosiaTheme.Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
            
            Text("No History Yet")
                .font(AmbrosiaTheme.Typography.title)
                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
            
            Text("Your past recommendations will appear here")
                .font(AmbrosiaTheme.Typography.body)
                .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyListView: some View {
        List {
            ForEach(store.entries) { entry in
                HistoryRowView(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticFeedback.light.trigger()
                        onSelectEntry(entry)
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    store.deleteEntry(store.entries[index])
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - History Row

struct HistoryRowView: View {
    let entry: HistoryEntry
    
    var body: some View {
        HStack(spacing: AmbrosiaTheme.Spacing.md) {
            // Mode Icon
            Image(systemName: entry.mode == .individual ? "person.fill" : "person.3.fill")
                .font(.system(size: 20))
                .foregroundStyle(AmbrosiaTheme.Gradients.coralSunset)
                .frame(width: 40, height: 40)
                .background(AmbrosiaTheme.SemanticColors.surface)
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(dishName)
                    .font(AmbrosiaTheme.Typography.headline)
                    .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(formattedDate)
                    .font(AmbrosiaTheme.Typography.caption)
                    .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Restaurant
            if let restaurant = entry.restaurantName {
                Text(restaurant)
                    .font(AmbrosiaTheme.Typography.caption)
                    .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var dishName: String {
        switch entry.recommendation {
        case .individual(let rec):
            return rec.translation.localizedName
        case .group(let combo):
            return combo.name
        }
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.date, relativeTo: Date())
    }
}
