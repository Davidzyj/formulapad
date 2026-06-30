import Foundation

enum TemplateCatalog {
    static let all: [FormulaTemplate] = [
        FormulaTemplate(
            id: "percent",
            titleKey: "template.percent.title",
            subtitleKey: "template.percent.subtitle",
            icon: "percent",
            isPro: false,
            fields: [
                TemplateField(id: "part", titleKey: "template.percent.part", placeholder: "25", defaultValue: "25"),
                TemplateField(id: "whole", titleKey: "template.percent.whole", placeholder: "200", defaultValue: "200")
            ],
            calculate: { values, _ in
                let part = try number(values["part"])
                let whole = try number(values["whole"])
                guard abs(whole) > Double.ulpOfOne else { throw FormulaError.divideByZero }
                let result = part / whole * 100
                return TemplateResult(
                    expression: "\(ExpressionEvaluator.format(part)) / \(ExpressionEvaluator.format(whole)) * 100",
                    result: ExpressionEvaluator.format(result) + "%",
                    explanationKey: "template.percent.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "discount",
            titleKey: "template.discount.title",
            subtitleKey: "template.discount.subtitle",
            icon: "tag",
            isPro: false,
            fields: [
                TemplateField(id: "price", titleKey: "template.discount.price", placeholder: "299", defaultValue: "299"),
                TemplateField(id: "rate", titleKey: "template.discount.rate", placeholder: "15", defaultValue: "15")
            ],
            calculate: { values, _ in
                let price = try number(values["price"])
                let rate = try number(values["rate"])
                let result = price * (1 - rate / 100)
                return TemplateResult(
                    expression: "\(ExpressionEvaluator.format(price)) * (1 - \(ExpressionEvaluator.format(rate)) / 100)",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.discount.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "compound",
            titleKey: "template.compound.title",
            subtitleKey: "template.compound.subtitle",
            icon: "chart.line.uptrend.xyaxis",
            isPro: false,
            fields: [
                TemplateField(id: "principal", titleKey: "template.compound.principal", placeholder: "20000", defaultValue: "20000"),
                TemplateField(id: "rate", titleKey: "template.compound.rate", placeholder: "3.5", defaultValue: "3.5"),
                TemplateField(id: "years", titleKey: "template.compound.years", placeholder: "3", defaultValue: "3")
            ],
            calculate: { values, _ in
                let principal = try number(values["principal"])
                let rate = try number(values["rate"])
                let years = try number(values["years"])
                let result = principal * pow(1 + rate / 100, years)
                return TemplateResult(
                    expression: "\(ExpressionEvaluator.format(principal)) * (1 + \(ExpressionEvaluator.format(rate)) / 100)^\(ExpressionEvaluator.format(years))",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.compound.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "loan",
            titleKey: "template.loan.title",
            subtitleKey: "template.loan.subtitle",
            icon: "house",
            isPro: true,
            fields: [
                TemplateField(id: "amount", titleKey: "template.loan.amount", placeholder: "300000", defaultValue: "300000"),
                TemplateField(id: "rate", titleKey: "template.loan.rate", placeholder: "4.2", defaultValue: "4.2"),
                TemplateField(id: "months", titleKey: "template.loan.months", placeholder: "360", defaultValue: "360")
            ],
            calculate: { values, _ in
                let amount = try number(values["amount"])
                let annualRate = try number(values["rate"])
                let months = try number(values["months"])
                guard months > 0 else { throw FormulaError.domain }
                let monthlyRate = annualRate / 100 / 12
                let result: Double
                if abs(monthlyRate) < Double.ulpOfOne {
                    result = amount / months
                } else {
                    result = amount * monthlyRate / (1 - pow(1 + monthlyRate, -months))
                }
                return TemplateResult(
                    expression: "loan(\(ExpressionEvaluator.format(amount)), \(ExpressionEvaluator.format(annualRate))%, \(ExpressionEvaluator.format(months)))",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.loan.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "bmi",
            titleKey: "template.bmi.title",
            subtitleKey: "template.bmi.subtitle",
            icon: "figure.stand",
            isPro: false,
            fields: [
                TemplateField(id: "weight", titleKey: "template.bmi.weight", placeholder: "68", defaultValue: "68"),
                TemplateField(id: "height", titleKey: "template.bmi.height", placeholder: "1.72", defaultValue: "1.72")
            ],
            calculate: { values, _ in
                let weight = try number(values["weight"])
                let height = try number(values["height"])
                guard height > 0 else { throw FormulaError.domain }
                let result = weight / pow(height, 2)
                return TemplateResult(
                    expression: "\(ExpressionEvaluator.format(weight)) / \(ExpressionEvaluator.format(height))^2",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.bmi.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "average",
            titleKey: "template.average.title",
            subtitleKey: "template.average.subtitle",
            icon: "number",
            isPro: true,
            fields: [
                TemplateField(id: "values", titleKey: "template.average.values", placeholder: "12, 18, 21", defaultValue: "12, 18, 21")
            ],
            calculate: { values, _ in
                let numbers = try valuesList(values["values"])
                guard !numbers.isEmpty else { throw FormulaError.syntax }
                let result = numbers.reduce(0, +) / Double(numbers.count)
                return TemplateResult(
                    expression: "average(\(numbers.map(ExpressionEvaluator.format).joined(separator: ", ")))",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.average.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "triangle",
            titleKey: "template.triangle.title",
            subtitleKey: "template.triangle.subtitle",
            icon: "triangle",
            isPro: true,
            fields: [
                TemplateField(id: "base", titleKey: "template.triangle.base", placeholder: "8", defaultValue: "8"),
                TemplateField(id: "height", titleKey: "template.triangle.height", placeholder: "5", defaultValue: "5")
            ],
            calculate: { values, _ in
                let base = try number(values["base"])
                let height = try number(values["height"])
                let result = base * height / 2
                return TemplateResult(
                    expression: "\(ExpressionEvaluator.format(base)) * \(ExpressionEvaluator.format(height)) / 2",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.triangle.explanation"
                )
            }
        ),
        FormulaTemplate(
            id: "speed",
            titleKey: "template.speed.title",
            subtitleKey: "template.speed.subtitle",
            icon: "speedometer",
            isPro: true,
            fields: [
                TemplateField(id: "distance", titleKey: "template.speed.distance", placeholder: "120", defaultValue: "120"),
                TemplateField(id: "time", titleKey: "template.speed.time", placeholder: "2", defaultValue: "2")
            ],
            calculate: { values, _ in
                let distance = try number(values["distance"])
                let time = try number(values["time"])
                guard abs(time) > Double.ulpOfOne else { throw FormulaError.divideByZero }
                let result = distance / time
                return TemplateResult(
                    expression: "\(ExpressionEvaluator.format(distance)) / \(ExpressionEvaluator.format(time))",
                    result: ExpressionEvaluator.format(result),
                    explanationKey: "template.speed.explanation"
                )
            }
        )
    ]

    private static func number(_ raw: String?) throws -> Double {
        guard let raw, let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw FormulaError.syntax
        }
        guard value.isFinite else { throw FormulaError.domain }
        return value
    }

    private static func valuesList(_ raw: String?) throws -> [Double] {
        guard let raw else { throw FormulaError.syntax }
        return try raw
            .split(separator: ",")
            .map {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let value = Double(trimmed), value.isFinite else {
                    throw FormulaError.syntax
                }
                return value
            }
    }
}

