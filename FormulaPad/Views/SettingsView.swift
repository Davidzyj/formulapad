import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showingPro = false

    private let privacyURL = URL(string: "https://davidzyj.github.io/formulapad/privacy.html")!
    private let supportURL = URL(string: "https://davidzyj.github.io/formulapad/support.html")!
    private let contactURL = URL(string: "mailto:jay212315@gmail.com?subject=FormulaPad%20Support")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ScreenHeader(title: store.t("settings.title"), subtitle: store.t("settings.local"))

                    Panel {
                        Text(store.t("settings.language"))
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                        Picker(store.t("settings.language"), selection: Binding(
                            get: { store.languagePreference },
                            set: { store.setLanguagePreference($0) }
                        )) {
                            Text(store.t("settings.language.auto")).tag(AppLanguagePreference.automatic)
                            Text(store.t("settings.language.en")).tag(AppLanguagePreference.english)
                            Text(store.t("settings.language.zh")).tag(AppLanguagePreference.simplifiedChinese)
                            Text(store.t("settings.language.ja")).tag(AppLanguagePreference.japanese)
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(AppColor.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Panel {
                        if purchaseManager.isPro {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppColor.success)
                                Text(store.t("pro.owned"))
                                    .font(.headline)
                                    .foregroundStyle(AppColor.ink)
                                Spacer()
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(store.t("pro.title"))
                                    .font(.headline)
                                    .foregroundStyle(AppColor.ink)
                                Text(store.t("pro.body"))
                                    .font(.subheadline)
                                    .foregroundStyle(AppColor.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button {
                                    showingPro = true
                                } label: {
                                    Label(store.t("common.unlock"), systemImage: "sparkles")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }
                    }

                    Panel {
                        settingsButton(title: store.t("settings.privacy"), systemImage: "hand.raised") {
                            open(privacyURL)
                        }
                        divider
                        settingsButton(title: store.t("settings.support"), systemImage: "questionmark.circle") {
                            open(supportURL)
                        }
                        divider
                        settingsButton(title: store.t("settings.contact"), systemImage: "envelope") {
                            open(contactURL)
                        }
                    }

                    Text(store.t("settings.version"))
                        .font(.footnote)
                        .foregroundStyle(AppColor.mutedInk)
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .sheet(isPresented: $showingPro) {
                ProPurchaseView()
                    .environmentObject(store)
                    .environmentObject(purchaseManager)
            }
            .formulaPadScreen()
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.line)
            .frame(height: 1)
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 24)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.mutedInk)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

struct ProPurchaseView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Panel {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(AppColor.amber)
                            .frame(maxWidth: .infinity)

                        Text(store.t("pro.title"))
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)

                        Text(store.t("pro.subtitle"))
                            .font(.headline)
                            .foregroundStyle(AppColor.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)

                        Text(store.t("pro.body"))
                            .font(.body)
                            .foregroundStyle(AppColor.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }

                    if purchaseManager.isPro {
                        Panel {
                            Label(store.t("pro.owned"), systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(AppColor.success)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else {
                        Panel {
                            if purchaseManager.isLoading {
                                ProgressView(store.t("pro.loading"))
                                    .tint(AppColor.primary)
                                    .foregroundStyle(AppColor.ink)
                                    .frame(maxWidth: .infinity)
                            } else if let product = purchaseManager.proProduct {
                                Button {
                                    Task {
                                        await purchaseManager.purchasePro()
                                        if purchaseManager.isPro {
                                            store.flash(store.t("pro.owned"))
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    Label("\(store.t("pro.once")) \(product.displayPrice)", systemImage: "lock.open")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            } else {
                                Text(store.t("pro.unavailable"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColor.warning)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Button {
                                    Task { await purchaseManager.loadProducts() }
                                } label: {
                                    Label(store.t("common.restore"), systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            Button {
                                Task {
                                    await purchaseManager.restore()
                                    store.flash(store.t("pro.restoreDone"))
                                    if purchaseManager.isPro {
                                        dismiss()
                                    }
                                }
                            } label: {
                                Label(store.t("common.restore"), systemImage: "arrow.clockwise.circle")
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            if let message = purchaseManager.purchaseMessage {
                                Text(message)
                                    .font(.footnote)
                                    .foregroundStyle(AppColor.danger)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(store.t("pro.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.t("common.done")) {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.primaryDark)
                }
            }
            .task {
                await purchaseManager.loadProducts()
                await purchaseManager.refreshEntitlements()
            }
            .formulaPadScreen()
        }
    }
}

