import SwiftUI
import UIKit

struct CalculateView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var expression = ""
    @State private var result = ""
    @State private var errorMessage: String?
    @State private var showingNoteEditor = false
    @State private var showingPro = false
    @FocusState private var focused: Field?

    private enum Field {
        case expression
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ScreenHeader(title: store.t("calculate.title"), subtitle: store.t("calculate.subtitle"))

                    Panel {
                        HStack {
                            Text(store.t("calculate.angle"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.secondaryInk)
                            Spacer()
                            Picker(store.t("calculate.angle"), selection: Binding(
                                get: { store.angleMode },
                                set: { store.setAngleMode($0) }
                            )) {
                                Text(store.t("calculate.degrees")).tag(AngleMode.degrees)
                                Text(store.t("calculate.radians")).tag(AngleMode.radians)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 210)
                        }

                        TextField(
                            "",
                            text: $expression,
                            prompt: Text(store.t("calculate.placeholder")).foregroundStyle(AppColor.placeholder),
                            axis: .vertical
                        )
                        .focused($focused, equals: .expression)
                        .formulaInputBehavior()
                        .font(.system(.title3, design: .monospaced))
                        .lineLimit(3...6)
                        .textInput()
                        .submitLabel(.done)
                        .onSubmit { focused = nil }

                        ScientificStrip { token in
                            insert(token)
                        }

                        CalculatorKeypad(
                            insert: insert,
                            backspace: backspace,
                            clear: clear
                        )

                        Button {
                            calculate()
                        } label: {
                            Label(store.t("common.calculate"), systemImage: "equal")
                        }
                        .buttonStyle(PrimaryButtonStyle(disabled: expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .disabled(expression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if !result.isEmpty {
                            ResultPanel(result: result, errorMessage: nil)

                            HStack(spacing: 10) {
                                Button {
                                    copyResult()
                                } label: {
                                    Label(store.t("common.copy"), systemImage: "doc.on.doc")
                                }
                                .buttonStyle(SecondaryButtonStyle())

                                ShareLink(item: shareText) {
                                    Label(store.t("common.share"), systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            Button {
                                focused = nil
                                if purchaseManager.isPro {
                                    showingNoteEditor = true
                                } else {
                                    showingPro = true
                                }
                            } label: {
                                Label(store.t("calculate.saveNote"), systemImage: "note.text.badge.plus")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        if let errorMessage {
                            ResultPanel(result: errorMessage, errorMessage: errorMessage)
                        }
                    }

                    Panel {
                        HStack {
                            Text(store.t("calculate.variableTitle"))
                                .font(.headline)
                                .foregroundStyle(AppColor.ink)
                            Spacer()
                        }
                        if store.variables.isEmpty {
                            Text(store.t("calculate.noVariables"))
                                .font(.subheadline)
                                .foregroundStyle(AppColor.secondaryInk)
                        } else {
                            FlowLayout(items: store.variables.keys.sorted()) { key in
                                let value = ExpressionEvaluator.format(store.variables[key] ?? 0)
                                TagLabel(text: "\(key)=\(value)", color: AppColor.primaryDark)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(store.t("common.done")) {
                        focused = nil
                    }
                    .foregroundStyle(AppColor.primaryDark)
                }
            }
            .sheet(isPresented: $showingNoteEditor) {
                NoteEditorView(expression: expression, result: result)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingPro) {
                ProPurchaseView()
                    .environmentObject(store)
                    .environmentObject(purchaseManager)
            }
            .onAppear {
                if !store.calculationDraft.isEmpty {
                    expression = store.calculationDraft
                    store.calculationDraft = ""
                }
                applyScreenshotStateIfNeeded()
            }
            .onChange(of: store.calculationDraft) { _, newValue in
                guard !newValue.isEmpty else { return }
                expression = newValue
                result = ""
                errorMessage = nil
                store.calculationDraft = ""
            }
            .formulaPadScreen()
        }
    }

    private var shareText: String {
        "\(store.t("share.note"))\n\(expression)\n= \(result)"
    }

    private func insert(_ token: String) {
        errorMessage = nil
        expression.append(token)
    }

    private func backspace() {
        errorMessage = nil
        guard !expression.isEmpty else { return }
        expression.removeLast()
    }

    private func clear() {
        focused = nil
        expression = ""
        result = ""
        errorMessage = nil
    }

    private func calculate() {
        focused = nil
        do {
            let evaluation = try ExpressionEvaluator.evaluateScript(
                expression,
                variables: store.variables,
                angleMode: store.angleMode
            )
            result = evaluation.formattedValue
            errorMessage = nil
            store.saveVariables(evaluation.variables)
            store.addHistory(
                CalculationEntry(expression: expression, result: result),
                isPro: purchaseManager.isPro
            )
            store.flash(store.t("common.saved"))
        } catch let formulaError as FormulaError {
            result = ""
            errorMessage = store.t(formulaError.key)
        } catch {
            result = ""
            errorMessage = store.t("calculate.invalidExpression")
        }
    }

    private func copyResult() {
        focused = nil
        UIPasteboard.general.string = result
        store.flash(store.t("calculate.copied"))
    }

    private func applyScreenshotStateIfNeeded() {
        #if DEBUG
        guard ScreenshotSupport.isEnabled, ScreenshotSupport.scenario == .calculate else { return }
        if expression.isEmpty {
            expression = "principal * (1 + rate)^years"
        }
        result = "22174.3575"
        errorMessage = nil
        #endif
    }
}

private struct ScientificStrip: View {
    let onToken: (String) -> Void

    private let tokens = ["sin(", "cos(", "tan(", "sqrt(", "log(", "ln(", "pi", "e"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tokens, id: \.self) { token in
                    Button {
                        onToken(token)
                    } label: {
                        Text(token)
                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                            .foregroundStyle(AppColor.primaryDark)
                            .frame(minWidth: 54)
                            .padding(.vertical, 9)
                            .background(AppColor.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CalculatorKeypad: View {
    let insert: (String) -> Void
    let backspace: () -> Void
    let clear: () -> Void

    private let rows: [[String]] = [
        ["7", "8", "9", "/", "("],
        ["4", "5", "6", "*", ")"],
        ["1", "2", "3", "-", "^"],
        ["0", ".", "%", "+", "!"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: clear) {
                    Label("C", systemImage: "xmark.circle")
                }
                .foregroundStyle(AppColor.danger)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(AppColor.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button(action: backspace) {
                    Label("", systemImage: "delete.left")
                        .labelStyle(.iconOnly)
                }
                .foregroundStyle(AppColor.primaryDark)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(AppColor.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            insert(item == "%" ? "/100" : item)
                        } label: {
                            Text(item)
                                .font(.headline)
                                .foregroundStyle(["/", "*", "-", "+", "^", "!", "(", ")"].contains(item) ? AppColor.primaryDark : AppColor.ink)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(AppColor.surfaceAlt)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct ResultPanel: View {
    @EnvironmentObject private var store: FormulaPadStore
    let result: String
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(errorMessage == nil ? store.t("common.result") : store.t("common.error"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(errorMessage == nil ? AppColor.secondaryInk : AppColor.danger)
            Text(result)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .foregroundStyle(errorMessage == nil ? AppColor.ink : AppColor.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(errorMessage == nil ? AppColor.surfaceAlt : AppColor.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
