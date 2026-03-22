import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("custom_gemini_api_key") private var customKey: String = ""
    @State private var isSecured: Bool = true

    var body: some View {
        ZStack {
            NodTheme.Cinematic.deepBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: NodTheme.Spacing.xl) {
                    Color.clear.frame(height: 72)

                    // MARK: API Configuration Section

                    VStack(alignment: .leading, spacing: NodTheme.Spacing.sm) {
                        Text("API Configuration")
                            .font(NodTheme.Typography.caption)
                            .foregroundColor(NodTheme.Cinematic.smokeGray)
                            .padding(.horizontal, NodTheme.Spacing.sm)

                        HStack(spacing: NodTheme.Spacing.md) {
                            Group {
                                if isSecured {
                                    SecureField("Gemini API Key", text: $customKey)
                                } else {
                                    TextField("Gemini API Key", text: $customKey)
                                }
                            }
                            .font(NodTheme.Typography.body)
                            .foregroundColor(NodTheme.Cinematic.pureWhite)
                            .tint(NodTheme.Cinematic.amber)

                            Button {
                                isSecured.toggle()
                            } label: {
                                Image(systemName: isSecured ? "eye.slash" : "eye")
                                    .foregroundColor(NodTheme.Cinematic.smokeGray)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .padding(NodTheme.Spacing.lg)
                        .glassCard(cornerRadius: NodTheme.Radius.lg)

                        Text("Enter a custom API Key to override the built-in key. This allows key updates without rebuilding the app.")
                            .font(NodTheme.Typography.caption)
                            .foregroundColor(NodTheme.Cinematic.smokeGray)
                            .padding(.horizontal, NodTheme.Spacing.sm)
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
                .padding(.horizontal, NodTheme.Spacing.xl)
                .padding(.bottom, NodTheme.Spacing.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .floatingNavBar(
            title: "Settings",
            trailing: .init(icon: "xmark") { dismiss() }
        )
    }
}
