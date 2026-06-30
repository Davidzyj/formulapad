import XCTest
@testable import FormulaPad

@MainActor
final class FormulaPadCoreTests: XCTestCase {
    func testExpressionEvaluatorHandlesCompoundInterest() throws {
        let result = try ExpressionEvaluator.evaluateScript(
            "20000 * (1 + 0.035)^3",
            variables: [:],
            angleMode: .degrees
        )

        XCTAssertEqual(result.formattedValue, "22174.3575")
    }

    func testExpressionEvaluatorStoresVariables() throws {
        let result = try ExpressionEvaluator.evaluateScript(
            "price = 299; count = 12; price * count",
            variables: [:],
            angleMode: .degrees
        )

        XCTAssertEqual(result.formattedValue, "3588")
        XCTAssertEqual(result.variables["price"], 299)
        XCTAssertEqual(result.variables["count"], 12)
    }

    func testDegreeModeForSine() throws {
        let result = try ExpressionEvaluator.evaluateScript(
            "sin(30)",
            variables: [:],
            angleMode: .degrees
        )

        XCTAssertEqual(result.value, 0.5, accuracy: 0.000001)
    }

    func testTemplateDiscount() throws {
        let template = try XCTUnwrap(TemplateCatalog.all.first { $0.id == "discount" })
        let store = FormulaPadStore()
        let result = try template.calculate(["price": "299", "rate": "15"], store)

        XCTAssertEqual(result.result, "254.15")
    }

    func testUnitConversion() {
        let category = UnitCatalog.all.first { $0.id == "length" }!
        let meter = category.units.first { $0.id == "meter" }!
        let kilometer = category.units.first { $0.id == "kilometer" }!

        XCTAssertEqual(UnitCatalog.convert(value: 1500, from: meter, to: kilometer), 1.5, accuracy: 0.000001)
    }
}
