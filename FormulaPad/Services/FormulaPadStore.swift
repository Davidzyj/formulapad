import Foundation
import SwiftUI

enum AppTab: Hashable {
    case calculate
    case history
    case notes
    case tools
    case settings
}

@MainActor
final class FormulaPadStore: ObservableObject {
    @Published var history: [CalculationEntry] = []
    @Published var notes: [NoteEntry] = []
    @Published var variables: [String: Double] = [:]
    @Published var angleMode: AngleMode = .degrees
    @Published var languagePreference: AppLanguagePreference = .automatic
    @Published var selectedTab: AppTab = .calculate
    @Published var calculationDraft: String = ""
    @Published var statusMessage: String?

    private let stateURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("FormulaPad", isDirectory: true)
        self.stateURL = directory.appendingPathComponent("app-state.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
        applyScreenshotStateIfNeeded()
    }

    var resolvedLanguage: ResolvedLanguage {
        L10n.resolvedLanguage(for: languagePreference)
    }

    func t(_ key: String) -> String {
        L10n.text(key, language: resolvedLanguage)
    }

    func setLanguagePreference(_ preference: AppLanguagePreference) {
        languagePreference = preference
        save()
    }

    func setAngleMode(_ mode: AngleMode) {
        angleMode = mode
        save()
    }

    func saveVariables(_ newVariables: [String: Double]) {
        variables = newVariables
        save()
    }

    func addHistory(_ entry: CalculationEntry, isPro: Bool) {
        var updated = history
        updated.insert(entry, at: 0)
        if !isPro, updated.count > 20 {
            updated = Array(updated.prefix(20))
        }
        history = updated
        save()
    }

    func deleteHistory(_ entry: CalculationEntry) {
        history = history.filter { $0.id != entry.id }
        save()
    }

    func clearHistory() {
        history = []
        save()
    }

    func toggleHistoryFavorite(_ entry: CalculationEntry) {
        var updated = history
        guard let index = updated.firstIndex(where: { $0.id == entry.id }) else { return }
        updated[index].isFavorite.toggle()
        history = updated
        save()
    }

    func reuse(_ entry: CalculationEntry) {
        calculationDraft = entry.expression
        selectedTab = .calculate
    }

    func upsertNote(_ note: NoteEntry) {
        var updated = notes
        if let index = updated.firstIndex(where: { $0.id == note.id }) {
            var edited = note
            edited.updatedAt = Date()
            updated[index] = edited
        } else {
            updated.insert(note, at: 0)
        }
        notes = updated
        save()
    }

    func deleteNote(_ note: NoteEntry) {
        notes = notes.filter { $0.id != note.id }
        save()
    }

    func toggleNoteFavorite(_ note: NoteEntry) {
        var updated = notes
        guard let index = updated.firstIndex(where: { $0.id == note.id }) else { return }
        updated[index].isFavorite.toggle()
        updated[index].updatedAt = Date()
        notes = updated
        save()
    }

    func flash(_ message: String) {
        statusMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: stateURL)
            let state = try decoder.decode(AppPersistedState.self, from: data)
            history = state.history
            notes = state.notes
            variables = state.variables
            angleMode = state.angleMode
            languagePreference = state.languagePreference
        } catch {
            history = AppPersistedState.empty.history
            notes = AppPersistedState.empty.notes
            variables = AppPersistedState.empty.variables
            angleMode = AppPersistedState.empty.angleMode
            languagePreference = AppPersistedState.empty.languagePreference
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: stateURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let state = AppPersistedState(
                history: history,
                notes: notes,
                variables: variables,
                angleMode: angleMode,
                languagePreference: languagePreference
            )
            let data = try encoder.encode(state)
            try data.write(to: stateURL, options: [.atomic])
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func applyScreenshotStateIfNeeded() {
        #if DEBUG
        guard ScreenshotSupport.isEnabled else { return }

        let now = Date()
        let copy = ScreenshotSupport.copy
        languagePreference = ScreenshotSupport.languagePreference
        angleMode = .degrees
        variables = [
            "principal": 20_000,
            "rate": 0.035,
            "years": 3,
            "price": 299,
            "count": 12
        ]
        history = [
            CalculationEntry(
                id: UUID(uuidString: "1F13B3F0-AF0F-4B5A-A8E3-AB26EF9E8A11")!,
                expression: "principal * (1 + rate)^years",
                result: "22174.3575",
                createdAt: now.addingTimeInterval(-1_800),
                isFavorite: true
            ),
            CalculationEntry(
                id: UUID(uuidString: "2A62504C-F571-4A4C-8DD6-BF5DBEF827D2")!,
                expression: "299 * 12",
                result: "3588",
                createdAt: now.addingTimeInterval(-4_200)
            ),
            CalculationEntry(
                id: UUID(uuidString: "68FD3145-464F-40E5-BD4E-13C9D8412774")!,
                expression: "20000 * (1 + 3.5 / 100)^3",
                result: "22174.3575",
                kind: .template,
                createdAt: now.addingTimeInterval(-8_600)
            ),
            CalculationEntry(
                id: UUID(uuidString: "9C849C97-C452-4D84-B73E-6DBAD64B69C2")!,
                expression: copy.conversionExpression,
                result: "78.8",
                kind: .conversion,
                createdAt: now.addingTimeInterval(-12_400)
            ),
            CalculationEntry(
                id: UUID(uuidString: "3E826AD5-EC8E-4D13-8E54-BF075DFD4D97")!,
                expression: "y = x^2",
                result: "-10...10",
                kind: .plot,
                createdAt: now.addingTimeInterval(-17_000)
            )
        ]
        notes = [
            NoteEntry(
                id: UUID(uuidString: "C02736E8-F8B8-4CB0-AD37-56F0C842A9C9")!,
                title: copy.compoundNoteTitle,
                expression: "principal * (1 + rate)^years",
                result: "22174.3575",
                remarks: copy.compoundNoteRemarks,
                category: .finance,
                createdAt: now.addingTimeInterval(-20_000),
                updatedAt: now.addingTimeInterval(-1_200),
                isFavorite: true
            ),
            NoteEntry(
                id: UUID(uuidString: "9F5E2FE4-A7E7-48C7-81B4-4BE6B1519300")!,
                title: copy.discountNoteTitle,
                expression: "299 * (1 - 15 / 100)",
                result: "254.15",
                remarks: copy.discountNoteRemarks,
                category: .work,
                createdAt: now.addingTimeInterval(-30_000),
                updatedAt: now.addingTimeInterval(-9_000)
            )
        ]
        calculationDraft = ScreenshotSupport.scenario == .calculate ? "principal * (1 + rate)^years" : ""
        selectedTab = ScreenshotSupport.selectedTab
        statusMessage = nil
        #endif
    }
}

enum ScreenshotScenario: String {
    case calculate
    case history
    case notes
    case templates
    case convert
    case plot
}

enum ScreenshotSupport {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["FORMULAPAD_SCREENSHOT_MODE"] == "1"
        #else
        false
        #endif
    }

    static var scenario: ScreenshotScenario? {
        #if DEBUG
        guard isEnabled, let rawValue = ProcessInfo.processInfo.environment["FORMULAPAD_SCREENSHOT_SCREEN"] else {
            return nil
        }
        return ScreenshotScenario(rawValue: rawValue)
        #else
        return nil
        #endif
    }

    static var languagePreference: AppLanguagePreference {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["FORMULAPAD_SCREENSHOT_LANGUAGE"] {
        case "en", "en-US":
            return .english
        case "ja", "ja-JP":
            return .japanese
        case "zh-Hans", "zh", "zh-CN":
            return .simplifiedChinese
        default:
            return .simplifiedChinese
        }
        #else
        return .automatic
        #endif
    }

    static var copy: ScreenshotCopy {
        switch languagePreference {
        case .english:
            return ScreenshotCopy(
                conversionExpression: "26 Celsius -> Fahrenheit",
                compoundNoteTitle: "Compound Goal Check",
                compoundNoteRemarks: "Compare three-year principal growth and keep the review note handy.",
                discountNoteTitle: "Discount Purchase Estimate",
                discountNoteRemarks: "Save a common purchase discount with the formula behind it."
            )
        case .japanese:
            return ScreenshotCopy(
                conversionExpression: "26 摂氏 -> 華氏",
                compoundNoteTitle: "複利目標チェック",
                compoundNoteRemarks: "3年後の元本成長を比較し、見直し用のメモとして保存します。",
                discountNoteTitle: "割引購入の見積もり",
                discountNoteRemarks: "よく使う割引計算を、式と一緒に保存できます。"
            )
        case .simplifiedChinese, .automatic:
            return ScreenshotCopy(
                conversionExpression: "26 摄氏度 -> 华氏度",
                compoundNoteTitle: "复利目标检查",
                compoundNoteRemarks: "用于比较三年后的本金增长，适合每月复盘。",
                discountNoteTitle: "折扣采购估算",
                discountNoteRemarks: "保存常用采购折扣，方便回看计算依据。"
            )
        }
    }

    static var selectedTab: AppTab {
        switch scenario {
        case .history:
            return .history
        case .notes:
            return .notes
        case .templates, .convert, .plot:
            return .tools
        case .calculate, .none:
            return .calculate
        }
    }

    static var toolsSegment: ToolsSegment {
        switch scenario {
        case .convert:
            return .convert
        case .plot:
            return .plot
        case .templates, .calculate, .history, .notes, .none:
            return .templates
        }
    }

    static var templateFieldValues: [String: [String: String]] {
        guard scenario == .templates else { return [:] }
        return [
            "compound": [
                "principal": "20000",
                "rate": "3.5",
                "years": "3"
            ]
        ]
    }

    static var templateResults: [String: TemplateResult] {
        guard scenario == .templates else { return [:] }
        return [
            "compound": TemplateResult(
                expression: "20000 * (1 + 3.5 / 100)^3",
                result: "22174.3575",
                explanationKey: "template.compound.explanation"
            )
        ]
    }
}

struct ScreenshotCopy {
    let conversionExpression: String
    let compoundNoteTitle: String
    let compoundNoteRemarks: String
    let discountNoteTitle: String
    let discountNoteRemarks: String
}
