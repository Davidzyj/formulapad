import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: FormulaPadStore

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $store.selectedTab) {
                CalculateView()
                    .tabItem {
                        Label(store.t("tab.calculate"), systemImage: "function")
                    }
                    .tag(AppTab.calculate)

                HistoryView()
                    .tabItem {
                        Label(store.t("tab.history"), systemImage: "clock.arrow.circlepath")
                    }
                    .tag(AppTab.history)

                NotesView()
                    .tabItem {
                        Label(store.t("tab.notes"), systemImage: "note.text")
                    }
                    .tag(AppTab.notes)

                ToolsView()
                    .tabItem {
                        Label(store.t("tab.tools"), systemImage: "square.grid.2x2")
                    }
                    .tag(AppTab.tools)

                SettingsView()
                    .tabItem {
                        Label(store.t("tab.settings"), systemImage: "gearshape")
                    }
                    .tag(AppTab.settings)
            }
            .background(AppColor.background)

            if let message = store.statusMessage {
                ToastView(message: message)
                    .padding(.bottom, 66)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.statusMessage)
        .formulaPadScreen()
    }
}

struct ScreenHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColor.ink)
                .minimumScaleFactor(0.78)
                .lineLimit(2)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.white)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColor.primaryDark)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 18)
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AppColor.mutedInk)
            Text(title)
                .font(.body)
                .foregroundStyle(AppColor.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
    }
}

struct ProGateView: View {
    @EnvironmentObject private var store: FormulaPadStore
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Panel {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColor.amber)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.t("pro.title"))
                        .font(compact ? .headline : .title3.weight(.bold))
                        .foregroundStyle(AppColor.ink)
                    Text(store.t("pro.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !compact {
                Text(store.t("pro.body"))
                    .font(.subheadline)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: action) {
                Label(store.t("common.unlock"), systemImage: "lock.open")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct TextInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppColor.ink)
            .padding(12)
            .background(AppColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColor.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func textInput() -> some View {
        modifier(TextInputStyle())
    }
}

