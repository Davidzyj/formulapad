import Foundation

enum AppLanguagePreference: String, Codable, CaseIterable, Identifiable {
    case automatic
    case english
    case simplifiedChinese
    case japanese

    var id: String { rawValue }
}

enum ResolvedLanguage: String, Codable {
    case english
    case simplifiedChinese
    case japanese
}

enum AngleMode: String, Codable, CaseIterable, Identifiable {
    case degrees
    case radians

    var id: String { rawValue }
}

enum EntryKind: String, Codable, CaseIterable {
    case calculation
    case template
    case conversion
    case plot
}

struct CalculationEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var expression: String
    var result: String
    var kind: EntryKind
    var createdAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        expression: String,
        result: String,
        kind: EntryKind = .calculation,
        createdAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.expression = expression
        self.result = result
        self.kind = kind
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
}

enum NoteCategory: String, Codable, CaseIterable, Identifiable {
    case study
    case work
    case life
    case finance

    var id: String { rawValue }
}

struct NoteEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var expression: String
    var result: String
    var remarks: String
    var category: NoteCategory
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        expression: String,
        result: String,
        remarks: String = "",
        category: NoteCategory = .study,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.expression = expression
        self.result = result
        self.remarks = remarks
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
    }
}

struct AppPersistedState: Codable {
    var history: [CalculationEntry]
    var notes: [NoteEntry]
    var variables: [String: Double]
    var angleMode: AngleMode
    var languagePreference: AppLanguagePreference

    static let empty = AppPersistedState(
        history: [],
        notes: [],
        variables: [:],
        angleMode: .degrees,
        languagePreference: .automatic
    )
}

struct TemplateField: Identifiable {
    let id: String
    let titleKey: String
    let placeholder: String
    let defaultValue: String
}

struct FormulaTemplate: Identifiable {
    let id: String
    let titleKey: String
    let subtitleKey: String
    let icon: String
    let isPro: Bool
    let fields: [TemplateField]
    let calculate: ([String: String], FormulaPadStore) throws -> TemplateResult
}

struct TemplateResult {
    let expression: String
    let result: String
    let explanationKey: String
}

struct UnitDefinition: Identifiable {
    let id: String
    let titleKey: String
    let toBase: (Double) -> Double
    let fromBase: (Double) -> Double
}

struct UnitCategory: Identifiable {
    let id: String
    let titleKey: String
    let units: [UnitDefinition]
}
