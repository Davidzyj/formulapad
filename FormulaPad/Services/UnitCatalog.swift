import Foundation

enum UnitCatalog {
    static let all: [UnitCategory] = [
        UnitCategory(
            id: "length",
            titleKey: "unit.length",
            units: [
                UnitDefinition(id: "meter", titleKey: "unit.meter", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "kilometer", titleKey: "unit.kilometer", toBase: { $0 * 1000 }, fromBase: { $0 / 1000 }),
                UnitDefinition(id: "centimeter", titleKey: "unit.centimeter", toBase: { $0 / 100 }, fromBase: { $0 * 100 }),
                UnitDefinition(id: "mile", titleKey: "unit.mile", toBase: { $0 * 1609.344 }, fromBase: { $0 / 1609.344 }),
                UnitDefinition(id: "foot", titleKey: "unit.foot", toBase: { $0 * 0.3048 }, fromBase: { $0 / 0.3048 })
            ]
        ),
        UnitCategory(
            id: "weight",
            titleKey: "unit.weight",
            units: [
                UnitDefinition(id: "kilogram", titleKey: "unit.kilogram", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "gram", titleKey: "unit.gram", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
                UnitDefinition(id: "pound", titleKey: "unit.pound", toBase: { $0 * 0.45359237 }, fromBase: { $0 / 0.45359237 })
            ]
        ),
        UnitCategory(
            id: "area",
            titleKey: "unit.area",
            units: [
                UnitDefinition(id: "squareMeter", titleKey: "unit.squareMeter", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "squareFoot", titleKey: "unit.squareFoot", toBase: { $0 * 0.09290304 }, fromBase: { $0 / 0.09290304 }),
                UnitDefinition(id: "acre", titleKey: "unit.acre", toBase: { $0 * 4046.8564224 }, fromBase: { $0 / 4046.8564224 })
            ]
        ),
        UnitCategory(
            id: "volume",
            titleKey: "unit.volume",
            units: [
                UnitDefinition(id: "liter", titleKey: "unit.liter", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "milliliter", titleKey: "unit.milliliter", toBase: { $0 / 1000 }, fromBase: { $0 * 1000 }),
                UnitDefinition(id: "gallon", titleKey: "unit.gallon", toBase: { $0 * 3.785411784 }, fromBase: { $0 / 3.785411784 })
            ]
        ),
        UnitCategory(
            id: "temperature",
            titleKey: "unit.temperature",
            units: [
                UnitDefinition(id: "celsius", titleKey: "unit.celsius", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "fahrenheit", titleKey: "unit.fahrenheit", toBase: { ($0 - 32) * 5 / 9 }, fromBase: { $0 * 9 / 5 + 32 }),
                UnitDefinition(id: "kelvin", titleKey: "unit.kelvin", toBase: { $0 - 273.15 }, fromBase: { $0 + 273.15 })
            ]
        ),
        UnitCategory(
            id: "time",
            titleKey: "unit.time",
            units: [
                UnitDefinition(id: "second", titleKey: "unit.second", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "minute", titleKey: "unit.minute", toBase: { $0 * 60 }, fromBase: { $0 / 60 }),
                UnitDefinition(id: "hour", titleKey: "unit.hour", toBase: { $0 * 3600 }, fromBase: { $0 / 3600 })
            ]
        ),
        UnitCategory(
            id: "speed",
            titleKey: "unit.speed",
            units: [
                UnitDefinition(id: "mps", titleKey: "unit.mps", toBase: { $0 }, fromBase: { $0 }),
                UnitDefinition(id: "kph", titleKey: "unit.kph", toBase: { $0 / 3.6 }, fromBase: { $0 * 3.6 }),
                UnitDefinition(id: "mph", titleKey: "unit.mph", toBase: { $0 * 0.44704 }, fromBase: { $0 / 0.44704 })
            ]
        )
    ]

    static func convert(value: Double, from: UnitDefinition, to: UnitDefinition) -> Double {
        to.fromBase(from.toBase(value))
    }
}

