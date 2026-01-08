import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("custom_gemini_api_key") private var customKey: String = ""
    @State private var isSecured: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if isSecured {
                            SecureField("Gemini API Key", text: $customKey)
                        } else {
                            TextField("Gemini API Key", text: $customKey)
                        }
                        
                        Button {
                            isSecured.toggle()
                        } label: {
                            Image(systemName: isSecured ? "eye.slash" : "eye")
                                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                        }
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Enter a custom API Key here to override the built-in key. This allows you to update the key without rebuilding the app.")
                        .font(AmbrosiaTheme.Typography.caption)
                }
                
                Section {
                    Button("Clear Custom Key", role: .destructive) {
                        customKey = ""
                    }
                    .disabled(customKey.isEmpty)
                }
                
                Section {
                    Link("Get Gemini API Key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
