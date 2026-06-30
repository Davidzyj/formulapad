import SwiftUI

enum AppColor {
    static let background = Color(red: 0.965, green: 0.976, blue: 0.992)
    static let surface = Color.white
    static let surfaceAlt = Color(red: 0.925, green: 0.951, blue: 0.972)
    static let ink = Color(red: 0.055, green: 0.075, blue: 0.110)
    static let secondaryInk = Color(red: 0.305, green: 0.349, blue: 0.408)
    static let mutedInk = Color(red: 0.455, green: 0.502, blue: 0.565)
    static let placeholder = Color(red: 0.405, green: 0.455, blue: 0.525)
    static let disabledInk = Color(red: 0.505, green: 0.545, blue: 0.605)
    static let line = Color(red: 0.830, green: 0.865, blue: 0.900)
    static let primary = Color(red: 0.000, green: 0.455, blue: 0.580)
    static let primaryDark = Color(red: 0.000, green: 0.285, blue: 0.370)
    static let coral = Color(red: 0.890, green: 0.295, blue: 0.240)
    static let amber = Color(red: 0.945, green: 0.620, blue: 0.170)
    static let success = Color(red: 0.100, green: 0.560, blue: 0.355)
    static let warning = Color(red: 0.680, green: 0.340, blue: 0.045)
    static let danger = Color(red: 0.780, green: 0.125, blue: 0.125)
}

struct PrimaryButtonStyle: ButtonStyle {
    var disabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(disabled ? AppColor.disabledInk : AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppColor.primaryDark)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(AppColor.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.line, lineWidth: 1)
        )
    }
}

struct TagLabel: View {
    let text: String
    var color: Color = AppColor.primary

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

extension View {
    func formulaPadScreen() -> some View {
        self
            .background(AppColor.background.ignoresSafeArea())
            .preferredColorScheme(.light)
    }

    func formulaInputBehavior() -> some View {
        self
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
    }
}
