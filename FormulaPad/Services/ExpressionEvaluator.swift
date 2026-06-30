import Foundation

enum FormulaError: Error, LocalizedError {
    case syntax
    case divideByZero
    case unknownVariable(String)
    case invalidAssignment
    case domain

    var key: String {
        switch self {
        case .syntax:
            return "error.syntax"
        case .divideByZero:
            return "error.divideByZero"
        case .unknownVariable:
            return "error.unknownVariable"
        case .invalidAssignment:
            return "error.invalidAssignment"
        case .domain:
            return "error.domain"
        }
    }
}

struct EvaluationResult {
    let value: Double
    let variables: [String: Double]
    let formattedValue: String
}

enum ExpressionEvaluator {
    static func evaluateScript(
        _ input: String,
        variables: [String: Double],
        angleMode: AngleMode
    ) throws -> EvaluationResult {
        let statements = input
            .split(whereSeparator: { $0 == "\n" || $0 == ";" })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !statements.isEmpty else {
            throw FormulaError.syntax
        }

        var workingVariables = variables
        var finalValue: Double?

        for statement in statements {
            if let assignment = parseAssignment(statement) {
                let value = try Parser(
                    text: assignment.expression,
                    variables: workingVariables,
                    angleMode: angleMode
                ).parse()
                guard value.isFinite else { throw FormulaError.domain }
                workingVariables[assignment.name] = value
                finalValue = value
            } else if statement.contains("=") {
                throw FormulaError.invalidAssignment
            } else {
                let value = try Parser(
                    text: statement,
                    variables: workingVariables,
                    angleMode: angleMode
                ).parse()
                guard value.isFinite else { throw FormulaError.domain }
                finalValue = value
            }
        }

        guard let finalValue else {
            throw FormulaError.syntax
        }

        return EvaluationResult(
            value: finalValue,
            variables: workingVariables,
            formattedValue: format(finalValue)
        )
    }

    static func evaluateExpression(
        _ input: String,
        variables: [String: Double],
        angleMode: AngleMode
    ) throws -> Double {
        let value = try Parser(text: input, variables: variables, angleMode: angleMode).parse()
        guard value.isFinite else { throw FormulaError.domain }
        return value
    }

    static func format(_ value: Double) -> String {
        if value.isNaN || value.isInfinite {
            return "NaN"
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func parseAssignment(_ statement: String) -> (name: String, expression: String)? {
        guard let equalsIndex = statement.firstIndex(of: "=") else {
            return nil
        }
        let name = String(statement[..<equalsIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let expression = String(statement[statement.index(after: equalsIndex)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidVariableName(name), !expression.isEmpty else {
            return nil
        }
        let protectedNames = ["pi", "π", "e", "sin", "cos", "tan", "sqrt", "log", "ln"]
        guard !protectedNames.contains(name.lowercased()) else {
            return nil
        }
        return (name, expression)
    }

    private static func isValidVariableName(_ name: String) -> Bool {
        guard let first = name.first else { return false }
        guard first.isLetter || first == "_" else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    private final class Parser {
        private let characters: [Character]
        private let variables: [String: Double]
        private let angleMode: AngleMode
        private var index = 0

        init(text: String, variables: [String: Double], angleMode: AngleMode) {
            self.characters = Array(text.replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/"))
            self.variables = variables
            self.angleMode = angleMode
        }

        func parse() throws -> Double {
            let value = try parseExpression()
            skipSpaces()
            guard isAtEnd else {
                throw FormulaError.syntax
            }
            return value
        }

        private var isAtEnd: Bool {
            index >= characters.count
        }

        private func current() -> Character? {
            isAtEnd ? nil : characters[index]
        }

        private func advance() {
            index += 1
        }

        private func skipSpaces() {
            while let char = current(), char.isWhitespace {
                advance()
            }
        }

        private func match(_ character: Character) -> Bool {
            skipSpaces()
            guard current() == character else { return false }
            advance()
            return true
        }

        private func parseExpression() throws -> Double {
            var value = try parseTerm()
            while true {
                if match("+") {
                    value += try parseTerm()
                } else if match("-") {
                    value -= try parseTerm()
                } else {
                    return value
                }
            }
        }

        private func parseTerm() throws -> Double {
            var value = try parsePower()
            while true {
                if match("*") {
                    value *= try parsePower()
                } else if match("/") {
                    let divisor = try parsePower()
                    guard abs(divisor) > Double.ulpOfOne else {
                        throw FormulaError.divideByZero
                    }
                    value /= divisor
                } else {
                    return value
                }
            }
        }

        private func parsePower() throws -> Double {
            var value = try parseUnary()
            if match("^") {
                let exponent = try parsePower()
                value = pow(value, exponent)
                guard value.isFinite else { throw FormulaError.domain }
            }
            return value
        }

        private func parseUnary() throws -> Double {
            if match("+") {
                return try parseUnary()
            }
            if match("-") {
                return -(try parseUnary())
            }
            return try parsePostfix()
        }

        private func parsePostfix() throws -> Double {
            var value = try parsePrimary()
            while match("!") {
                value = try factorial(value)
            }
            return value
        }

        private func parsePrimary() throws -> Double {
            skipSpaces()
            if match("(") {
                let value = try parseExpression()
                guard match(")") else { throw FormulaError.syntax }
                return value
            }

            if let char = current(), char.isNumber || char == "." {
                return try parseNumber()
            }

            if let char = current(), char.isLetter || char == "_" || char == "π" {
                let identifier = parseIdentifier()
                skipSpaces()
                if match("(") {
                    let argument = try parseExpression()
                    guard match(")") else { throw FormulaError.syntax }
                    return try applyFunction(identifier, argument)
                }
                if identifier == "pi" || identifier == "π" {
                    return Double.pi
                }
                if identifier == "e" {
                    return Darwin.M_E
                }
                if let variable = variables[identifier] {
                    return variable
                }
                throw FormulaError.unknownVariable(identifier)
            }

            throw FormulaError.syntax
        }

        private func parseNumber() throws -> Double {
            let start = index
            var hasDecimal = false

            while let char = current() {
                if char.isNumber {
                    advance()
                } else if char == ".", !hasDecimal {
                    hasDecimal = true
                    advance()
                } else {
                    break
                }
            }

            if let char = current(), char == "e" || char == "E" {
                advance()
                if let sign = current(), sign == "+" || sign == "-" {
                    advance()
                }
                while let digit = current(), digit.isNumber {
                    advance()
                }
            }

            let raw = String(characters[start..<index])
            guard let value = Double(raw) else {
                throw FormulaError.syntax
            }
            return value
        }

        private func parseIdentifier() -> String {
            let start = index
            while let char = current(), char.isLetter || char.isNumber || char == "_" || char == "π" {
                advance()
            }
            return String(characters[start..<index]).lowercased()
        }

        private func applyFunction(_ name: String, _ rawArgument: Double) throws -> Double {
            let argument = angleMode == .degrees && ["sin", "cos", "tan"].contains(name)
                ? rawArgument * .pi / 180
                : rawArgument

            let value: Double
            switch name {
            case "sin":
                value = sin(argument)
            case "cos":
                value = cos(argument)
            case "tan":
                value = tan(argument)
            case "asin":
                value = asin(rawArgument)
            case "acos":
                value = acos(rawArgument)
            case "atan":
                value = atan(rawArgument)
            case "sqrt":
                guard rawArgument >= 0 else { throw FormulaError.domain }
                value = sqrt(rawArgument)
            case "log":
                guard rawArgument > 0 else { throw FormulaError.domain }
                value = log10(rawArgument)
            case "ln":
                guard rawArgument > 0 else { throw FormulaError.domain }
                value = log(rawArgument)
            case "abs":
                value = abs(rawArgument)
            case "exp":
                value = exp(rawArgument)
            case "floor":
                value = floor(rawArgument)
            case "ceil":
                value = ceil(rawArgument)
            default:
                throw FormulaError.syntax
            }

            guard value.isFinite else { throw FormulaError.domain }
            return value
        }

        private func factorial(_ value: Double) throws -> Double {
            guard value >= 0, value.rounded() == value, value <= 170 else {
                throw FormulaError.domain
            }
            if value == 0 { return 1 }
            return (1...Int(value)).reduce(1.0) { $0 * Double($1) }
        }
    }
}
