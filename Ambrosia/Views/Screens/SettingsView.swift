import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("custom_gemini_api_key") private var customKey: String = ""
    @State private var isSecured: Bool = true

    var body: some View {
        ZStack {
            AmbrosiaTheme.Cinematic.deepBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.xl) {
                    Color.clear.frame(height: 72)

                    // MARK: API Configuration Section

                    VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.sm) {
                        Text("API Configuration")
                            .font(AmbrosiaTheme.Typography.caption)
                            .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                            .padding(.horizontal, AmbrosiaTheme.Spacing.sm)

                        HStack(spacing: AmbrosiaTheme.Spacing.md) {
                            Group {
                                if isSecured {
                                    SecureField("Gemini API Key", text: $customKey)
                                } else {
                                    TextField("Gemini API Key", text: $customKey)
                                }
                            }
                            .font(AmbrosiaTheme.Typography.body)
                            .foregroundColor(AmbrosiaTheme.Cinematic.pureWhite)
                            .tint(AmbrosiaTheme.Cinematic.amber)

                            Button {
                                isSecured.toggle()
                            } label: {
                                Image(systemName: isSecured ? "eye.slash" : "eye")
                                    .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .padding(AmbrosiaTheme.Spacing.lg)
                        .glassCard(cornerRadius: AmbrosiaTheme.Radius.lg)

                        Text("Enter a custom API Key to override the built-in key. This allows key updates without rebuilding the app.")
                            .font(AmbrosiaTheme.Typography.caption)
                            .foregroundColor(AmbrosiaTheme.Cinematic.smokeGray)
                            .padding(.horizontal, AmbrosiaTheme.Spacing.sm)
                    }

                    // MARK: Actions

                    GlassButton(title: "Clear Custom Key", icon: "trash", variant: .secondary) {
                        customKey = ""
                    }
                    .disabled(customKey.isEmpty)
                    .opacity(customKey.isEmpty ? 0.4 : 1.0)

                    GlassButton(title: "Get Gemini API Key", icon: "arrow.up.right.square", variant: .ghost) {
                        openURL(URL(string: "https://aistudio.google.com/app/apikey")!)
                    }
                }
                .padding(.horizontal, AmbrosiaTheme.Spacing.xl)
                .padding(.bottom, AmbrosiaTheme.Spacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .floatingNavBar(
            title: "Settings",
            trailing: .init(icon: "xmark") { dismiss() }
        )
    }
}
