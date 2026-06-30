import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: FormulaPadStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ScreenHeader(title: store.t("history.title"), subtitle: store.t("history.limit"))

                    if store.history.isEmpty {
                        EmptyStateView(title: store.t("history.empty"), systemImage: "clock")
                    } else {
                        Button(role: .destructive) {
                            store.clearHistory()
                            store.flash(store.t("common.saved"))
                        } label: {
                            Label(store.t("history.clearAll"), systemImage: "trash")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.danger)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        LazyVStack(spacing: 10) {
                            ForEach(store.history) { entry in
                                HistoryRow(entry: entry)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .formulaPadScreen()
        }
    }
}

private struct HistoryRow: View {
    @EnvironmentObject private var store: FormulaPadStore
    let entry: CalculationEntry

    var body: some View {
        Panel {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.expression)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(AppColor.ink)
                        .lineLimit(3)
                        .textSelection(.enabled)
                    Text("= \(entry.result)")
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppColor.primaryDark)
                        .textSelection(.enabled)
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppColor.mutedInk)
                }

                Spacer()

                Button {
                    store.toggleHistoryFavorite(entry)
                } label: {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(entry.isFavorite ? AppColor.amber : AppColor.mutedInk)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button {
                    store.reuse(entry)
                } label: {
                    Label(store.t("history.reuse"), systemImage: "arrow.uturn.left")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(role: .destructive) {
                    store.deleteHistory(entry)
                } label: {
                    Label(store.t("common.delete"), systemImage: "trash")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var iconName: String {
        switch entry.kind {
        case .calculation:
            return "function"
        case .template:
            return "doc.text"
        case .conversion:
            return "arrow.left.arrow.right"
        case .plot:
            return "waveform.path.ecg"
        }
    }
}

