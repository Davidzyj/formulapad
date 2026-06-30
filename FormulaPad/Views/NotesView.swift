import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var editingNote: NoteEntry?
    @State private var showingPro = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ScreenHeader(title: store.t("notes.title"), subtitle: nil)

                    if purchaseManager.isPro {
                        if store.notes.isEmpty {
                            EmptyStateView(title: store.t("notes.empty"), systemImage: "note.text")
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(store.notes) { note in
                                    NoteRow(note: note) {
                                        editingNote = note
                                    }
                                }
                            }
                        }
                    } else {
                        ProGateView(compact: false) {
                            showingPro = true
                        }
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingNote) { note in
                NoteEditorView(existingNote: note)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingPro) {
                ProPurchaseView()
                    .environmentObject(store)
                    .environmentObject(purchaseManager)
            }
            .formulaPadScreen()
        }
    }
}

private struct NoteRow: View {
    @EnvironmentObject private var store: FormulaPadStore
    let note: NoteEntry
    let edit: () -> Void

    var body: some View {
        Panel {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(note.title)
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                            .lineLimit(2)
                        TagLabel(text: store.t("category.\(note.category.rawValue)"), color: AppColor.coral)
                    }

                    Text(note.expression)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(AppColor.secondaryInk)
                        .lineLimit(2)
                    Text("= \(note.result)")
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppColor.primaryDark)
                    if !note.remarks.isEmpty {
                        Text(note.remarks)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.secondaryInk)
                            .lineLimit(3)
                    }
                    Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppColor.mutedInk)
                }
                Spacer()
                Button {
                    store.toggleNoteFavorite(note)
                } label: {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(note.isFavorite ? AppColor.amber : AppColor.mutedInk)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button(action: edit) {
                    Label(store.t("common.edit"), systemImage: "pencil")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(role: .destructive) {
                    store.deleteNote(note)
                } label: {
                    Label(store.t("common.delete"), systemImage: "trash")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var expression: String
    @State private var result: String
    @State private var remarks: String
    @State private var category: NoteCategory
    @State private var isFavorite: Bool
    @State private var validationMessage: String?
    @FocusState private var focused: Field?

    private let existingID: UUID?
    private let createdAt: Date

    private enum Field {
        case title
        case remarks
    }

    init(expression: String, result: String) {
        _title = State(initialValue: "")
        _expression = State(initialValue: expression)
        _result = State(initialValue: result)
        _remarks = State(initialValue: "")
        _category = State(initialValue: .study)
        _isFavorite = State(initialValue: false)
        self.existingID = nil
        self.createdAt = Date()
    }

    init(existingNote: NoteEntry) {
        _title = State(initialValue: existingNote.title)
        _expression = State(initialValue: existingNote.expression)
        _result = State(initialValue: existingNote.result)
        _remarks = State(initialValue: existingNote.remarks)
        _category = State(initialValue: existingNote.category)
        _isFavorite = State(initialValue: existingNote.isFavorite)
        self.existingID = existingNote.id
        self.createdAt = existingNote.createdAt
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Panel {
                        Text(store.t("common.expression"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.secondaryInk)
                        Text(expression)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(AppColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("= \(result)")
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.primaryDark)
                    }

                    Panel {
                        labeledField(title: store.t("notes.titleField")) {
                            TextField(
                                "",
                                text: $title,
                                prompt: Text(store.t("notes.titlePlaceholder")).foregroundStyle(AppColor.placeholder)
                            )
                            .focused($focused, equals: .title)
                            .textInput()
                            .submitLabel(.next)
                            .onSubmit { focused = .remarks }
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Text(store.t("notes.category"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.secondaryInk)
                            Picker(store.t("notes.category"), selection: $category) {
                                ForEach(NoteCategory.allCases) { category in
                                    Text(store.t("category.\(category.rawValue)")).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Text(store.t("notes.remarks"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.secondaryInk)
                            ZStack(alignment: .topLeading) {
                                if remarks.isEmpty {
                                    Text(store.t("notes.remarksPlaceholder"))
                                        .foregroundStyle(AppColor.placeholder)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 18)
                                }
                                TextEditor(text: $remarks)
                                    .focused($focused, equals: .remarks)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(AppColor.ink)
                                    .padding(8)
                            }
                            .background(AppColor.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppColor.line, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        Toggle(isOn: $isFavorite) {
                            Text(store.t("common.favorite"))
                                .foregroundStyle(AppColor.ink)
                        }
                        .tint(AppColor.primary)

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.danger)
                        }

                        Button {
                            save()
                        } label: {
                            Label(store.t("common.save"), systemImage: "checkmark")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(store.t("notes.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.t("common.cancel")) {
                        focused = nil
                        dismiss()
                    }
                    .foregroundStyle(AppColor.primaryDark)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(store.t("common.done")) {
                        focused = nil
                    }
                    .foregroundStyle(AppColor.primaryDark)
                }
            }
            .formulaPadScreen()
        }
    }

    private func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.secondaryInk)
            content()
        }
    }

    private func save() {
        focused = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = store.t("notes.validationTitle")
            return
        }
        let note = NoteEntry(
            id: existingID ?? UUID(),
            title: trimmedTitle,
            expression: expression,
            result: result,
            remarks: remarks.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            createdAt: createdAt,
            updatedAt: Date(),
            isFavorite: isFavorite
        )
        store.upsertNote(note)
        store.flash(store.t("common.saved"))
        dismiss()
    }
}

