import SwiftUI

// MARK: - HistoryStore Environment Keys
// Allows any descendant view to access the shared HistoryStore and history sheet trigger
// without prop-drilling through deep view hierarchies.
//
// The real HistoryStore instance is always injected from AppRootView via store.historyStore.
// The default value is nil; views using this key require the env to be populated first.

private struct HistoryStoreKey: EnvironmentKey {
    static let defaultValue: HistoryStore? = nil
}

private struct ShowHistoryKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var historyStoreKey: HistoryStore? {
        get { self[HistoryStoreKey.self] }
        set { self[HistoryStoreKey.self] = newValue }
    }

    var showHistoryKey: Binding<Bool> {
        get { self[ShowHistoryKey.self] }
        set { self[ShowHistoryKey.self] = newValue }
    }
}
