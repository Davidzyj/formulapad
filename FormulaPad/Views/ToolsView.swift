import SwiftUI

enum ToolsSegment: String, CaseIterable, Identifiable {
    case templates
    case convert
    case plot

    var id: String { rawValue }
}

struct ToolsView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @State private var segment: ToolsSegment = .templates

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text(store.t("tools.segment.templates")).tag(ToolsSegment.templates)
                    Text(store.t("tools.segment.convert")).tag(ToolsSegment.convert)
                    Text(store.t("tools.segment.plot")).tag(ToolsSegment.plot)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                switch segment {
                case .templates:
                    TemplatesView()
                case .convert:
                    ConverterView()
                case .plot:
                    PlotView()
                }
            }
            .formulaPadScreen()
        }
    }
}

struct TemplatesView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var expandedTemplateID: String?
    @State private var fieldValues: [String: [String: String]] = [:]
    @State private var results: [String: TemplateResult] = [:]
    @State private var errors: [String: String] = [:]
    @State private var showingPro = false
    @FocusState private var focusedField: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenHeader(title: store.t("templates.title"), subtitle: nil)

                ForEach(TemplateCatalog.all) { template in
                    templatePanel(template)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("common.done")) {
                    focusedField = nil
                }
                .foregroundStyle(AppColor.primaryDark)
            }
        }
        .sheet(isPresented: $showingPro) {
            ProPurchaseView()
                .environmentObject(store)
                .environmentObject(purchaseManager)
        }
        .formulaPadScreen()
    }

    private func templatePanel(_ template: FormulaTemplate) -> some View {
        Panel {
            HStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 32, height: 32)
                    .background(AppColor.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(store.t(template.titleKey))
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                            .lineLimit(1)
                        if template.isPro {
                            TagLabel(text: store.t("common.pro"), color: AppColor.amber)
                        }
                    }
                    Text(store.t(template.subtitleKey))
                        .font(.subheadline)
                        .foregroundStyle(AppColor.secondaryInk)
                        .lineLimit(2)
                }
                Spacer()
            }

            if template.isPro && !purchaseManager.isPro {
                Button {
                    focusedField = nil
                    showingPro = true
                } label: {
                    Label(store.t("common.unlock"), systemImage: "lock")
                }
                .buttonStyle(SecondaryButtonStyle())
            } else if expandedTemplateID == template.id {
                templateForm(template)
            } else {
                Button {
                    focusedField = nil
                    expandedTemplateID = template.id
                    ensureDefaults(for: template)
                } label: {
                    Label(store.t("templates.calculate"), systemImage: "play")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private func templateForm(_ template: FormulaTemplate) -> some View {
        VStack(spacing: 10) {
            ForEach(template.fields) { field in
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.t(field.titleKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.secondaryInk)
                    TextField(
                        "",
                        text: binding(for: template, field: field),
                        prompt: Text(field.placeholder).foregroundStyle(AppColor.placeholder)
                    )
                    .keyboardType(field.id == "values" ? .numbersAndPunctuation : .decimalPad)
                    .focused($focusedField, equals: "\(template.id).\(field.id)")
                    .textInput()
                }
            }

            if let error = errors[template.id] {
                Text(error)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let result = results[template.id] {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.result)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .foregroundStyle(AppColor.primaryDark)
                    Text(store.t(result.explanationKey))
                        .font(.subheadline)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColor.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    focusedField = nil
                    store.addHistory(
                        CalculationEntry(expression: result.expression, result: result.result, kind: .template),
                        isPro: purchaseManager.isPro
                    )
                    store.flash(store.t("templates.resultSaved"))
                } label: {
                    Label(store.t("templates.saveHistory"), systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Button {
                run(template)
            } label: {
                Label(store.t("common.calculate"), systemImage: "equal")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func ensureDefaults(for template: FormulaTemplate) {
        guard fieldValues[template.id] == nil else { return }
        var defaults: [String: String] = [:]
        template.fields.forEach { defaults[$0.id] = $0.defaultValue }
        var updated = fieldValues
        updated[template.id] = defaults
        fieldValues = updated
    }

    private func binding(for template: FormulaTemplate, field: TemplateField) -> Binding<String> {
        Binding(
            get: {
                fieldValues[template.id]?[field.id] ?? field.defaultValue
            },
            set: { newValue in
                var updated = fieldValues
                var values = updated[template.id] ?? [:]
                values[field.id] = newValue
                updated[template.id] = values
                fieldValues = updated
            }
        )
    }

    private func run(_ template: FormulaTemplate) {
        focusedField = nil
        ensureDefaults(for: template)
        do {
            let result = try template.calculate(fieldValues[template.id] ?? [:], store)
            var updatedResults = results
            updatedResults[template.id] = result
            results = updatedResults

            var updatedErrors = errors
            updatedErrors[template.id] = nil
            errors = updatedErrors
        } catch let formulaError as FormulaError {
            var updatedErrors = errors
            updatedErrors[template.id] = store.t(formulaError.key)
            errors = updatedErrors
        } catch {
            var updatedErrors = errors
            updatedErrors[template.id] = store.t("common.invalidNumber")
            errors = updatedErrors
        }
    }
}

struct ConverterView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var categoryID = UnitCatalog.all[0].id
    @State private var fromID = UnitCatalog.all[0].units[0].id
    @State private var toID = UnitCatalog.all[0].units[1].id
    @State private var value = "1"
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenHeader(title: store.t("convert.title"), subtitle: nil)

                Panel {
                    picker(title: store.t("convert.category"), selection: $categoryID) {
                        ForEach(UnitCatalog.all) { category in
                            Text(store.t(category.titleKey)).tag(category.id)
                        }
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(store.t("convert.value"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.secondaryInk)
                        TextField(
                            "",
                            text: $value,
                            prompt: Text("1").foregroundStyle(AppColor.placeholder)
                        )
                        .keyboardType(.decimalPad)
                        .focused($focused)
                        .textInput()
                    }

                    HStack(spacing: 10) {
                        picker(title: store.t("convert.from"), selection: $fromID) {
                            ForEach(currentCategory.units) { unit in
                                Text(store.t(unit.titleKey)).tag(unit.id)
                            }
                        }
                        picker(title: store.t("convert.to"), selection: $toID) {
                            ForEach(currentCategory.units) { unit in
                                Text(store.t(unit.titleKey)).tag(unit.id)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.t("common.result"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.secondaryInk)
                        Text(resultText)
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                            .foregroundStyle(AppColor.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(AppColor.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button {
                        saveConversion()
                    } label: {
                        Label(store.t("convert.save"), systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(PrimaryButtonStyle(disabled: numericValue == nil))
                    .disabled(numericValue == nil)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: categoryID) { _, _ in
            resetUnits()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("common.done")) {
                    focused = false
                }
                .foregroundStyle(AppColor.primaryDark)
            }
        }
        .formulaPadScreen()
    }

    private var currentCategory: UnitCategory {
        UnitCatalog.all.first { $0.id == categoryID } ?? UnitCatalog.all[0]
    }

    private var fromUnit: UnitDefinition {
        currentCategory.units.first { $0.id == fromID } ?? currentCategory.units[0]
    }

    private var toUnit: UnitDefinition {
        currentCategory.units.first { $0.id == toID } ?? currentCategory.units[min(1, currentCategory.units.count - 1)]
    }

    private var numericValue: Double? {
        Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var convertedValue: Double? {
        guard let numericValue else { return nil }
        return UnitCatalog.convert(value: numericValue, from: fromUnit, to: toUnit)
    }

    private var resultText: String {
        guard let convertedValue else {
            return store.t("common.invalidNumber")
        }
        return "\(ExpressionEvaluator.format(convertedValue)) \(store.t(toUnit.titleKey))"
    }

    private func picker<Content: View>(title: String, selection: Binding<String>, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.secondaryInk)
            Picker(title, selection: selection) {
                content()
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(AppColor.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func resetUnits() {
        let units = currentCategory.units
        fromID = units[0].id
        toID = units[min(1, units.count - 1)].id
    }

    private func saveConversion() {
        focused = false
        guard let numericValue, let convertedValue else { return }
        let expression = "\(ExpressionEvaluator.format(numericValue)) \(store.t(fromUnit.titleKey)) -> \(store.t(toUnit.titleKey))"
        store.addHistory(
            CalculationEntry(expression: expression, result: ExpressionEvaluator.format(convertedValue), kind: .conversion),
            isPro: purchaseManager.isPro
        )
        store.flash(store.t("convert.saved"))
    }
}

struct PlotView: View {
    @EnvironmentObject private var store: FormulaPadStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var expression = "x^2"
    @State private var samples: [PlotSample] = []
    @State private var errorMessage: String?
    @State private var showingPro = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenHeader(title: store.t("plot.title"), subtitle: store.t("plot.range"))

                if purchaseManager.isPro {
                    Panel {
                        TextField(
                            "",
                            text: $expression,
                            prompt: Text(store.t("plot.placeholder")).foregroundStyle(AppColor.placeholder)
                        )
                        .focused($focused)
                        .textInput()
                        .submitLabel(.done)
                        .onSubmit { focused = false }

                        Button {
                            draw()
                        } label: {
                            Label(store.t("plot.draw"), systemImage: "waveform.path.ecg")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        PlotGraph(samples: samples)
                            .frame(height: 260)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.danger)
                        }

                        Button {
                            savePlot()
                        } label: {
                            Label(store.t("plot.save"), systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(samples.isEmpty)
                    }
                } else {
                    ProGateView(compact: false) {
                        showingPro = true
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("common.done")) {
                    focused = false
                }
                .foregroundStyle(AppColor.primaryDark)
            }
        }
        .onAppear {
            if purchaseManager.isPro, samples.isEmpty {
                draw()
            }
        }
        .sheet(isPresented: $showingPro) {
            ProPurchaseView()
                .environmentObject(store)
                .environmentObject(purchaseManager)
        }
        .formulaPadScreen()
    }

    private func draw() {
        focused = false
        guard expression.lowercased().contains("x") else {
            errorMessage = store.t("plot.invalid")
            samples = []
            return
        }
        var generated: [PlotSample] = []
        for step in 0...240 {
            let x = -10.0 + Double(step) * 20.0 / 240.0
            do {
                let y = try ExpressionEvaluator.evaluateExpression(
                    expression,
                    variables: store.variables.merging(["x": x]) { _, new in new },
                    angleMode: store.angleMode
                )
                if y.isFinite, abs(y) < 1_000_000 {
                    generated.append(PlotSample(x: x, y: y))
                }
            } catch {
                continue
            }
        }
        if generated.isEmpty {
            samples = []
            errorMessage = store.t("plot.invalid")
        } else {
            samples = generated
            errorMessage = nil
        }
    }

    private func savePlot() {
        focused = false
        store.addHistory(
            CalculationEntry(expression: "y = \(expression)", result: store.t("plot.range"), kind: .plot),
            isPro: purchaseManager.isPro
        )
        store.flash(store.t("plot.saved"))
    }
}

struct PlotSample {
    let x: Double
    let y: Double
}

struct PlotGraph: View {
    let samples: [PlotSample]

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(AppColor.surfaceAlt))

            guard samples.count > 1 else {
                drawEmptyGrid(context: context, size: size)
                return
            }

            let yValues = samples.map(\.y)
            var yMin = min(yValues.min() ?? -1, -1)
            var yMax = max(yValues.max() ?? 1, 1)
            if abs(yMax - yMin) < 0.001 {
                yMin -= 1
                yMax += 1
            }

            let plotRect = rect.insetBy(dx: 14, dy: 14)
            drawGrid(context: context, rect: plotRect)

            func point(_ sample: PlotSample) -> CGPoint {
                let xRatio = (sample.x + 10) / 20
                let yRatio = (sample.y - yMin) / (yMax - yMin)
                return CGPoint(
                    x: plotRect.minX + plotRect.width * xRatio,
                    y: plotRect.maxY - plotRect.height * yRatio
                )
            }

            var path = Path()
            path.move(to: point(samples[0]))
            samples.dropFirst().forEach { path.addLine(to: point($0)) }
            context.stroke(path, with: .color(AppColor.coral), lineWidth: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.line, lineWidth: 1)
        )
    }

    private func drawEmptyGrid(context: GraphicsContext, size: CGSize) {
        drawGrid(context: context, rect: CGRect(origin: .zero, size: size).insetBy(dx: 14, dy: 14))
    }

    private func drawGrid(context: GraphicsContext, rect: CGRect) {
        var grid = Path()
        for index in 0...4 {
            let x = rect.minX + rect.width * CGFloat(index) / 4
            grid.move(to: CGPoint(x: x, y: rect.minY))
            grid.addLine(to: CGPoint(x: x, y: rect.maxY))
            let y = rect.minY + rect.height * CGFloat(index) / 4
            grid.move(to: CGPoint(x: rect.minX, y: y))
            grid.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        context.stroke(grid, with: .color(AppColor.line), lineWidth: 1)
    }
}

