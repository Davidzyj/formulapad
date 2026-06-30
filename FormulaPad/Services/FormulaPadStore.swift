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
}

