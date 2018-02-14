//
//  EvalBenchmarkHelpers.swift
//  Benchmark
//
//  Created by Nick Lockwood on 13/02/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

private let number = DataType(type: Double.self, literals: [
    Literal<Double> { value, _ in Double(value) },
    Literal<Double>("pi", convertsTo: Double.pi),
    Literal<Double>("a", convertsTo: 5.0),
    Literal<Double>("b", convertsTo: 6.0),
    Literal<Double>("c", convertsTo: 7.0),
    Literal<Double>("hello", convertsTo: -5.0),
    Literal<Double>("world", convertsTo: -3.0),
]) { arg, _ in "\(arg)" }

private let multiplication = Function<Double>(Variable<Double>("lhs") +
    Keyword("*") + Variable<Double>("rhs")) { arguments, _, _ in
    guard let lhs = arguments["lhs"] as? Double,
        let rhs = arguments["rhs"] as? Double else { return nil }
    return lhs * rhs
}

private let division = Function<Double>(Variable<Double>("lhs") +
    Keyword("/") + Variable<Double>("rhs")) { arguments, _, _ in
        guard let lhs = arguments["lhs"] as? Double,
            let rhs = arguments["rhs"] as? Double else { return nil }
        return lhs / rhs
}

private let addition = Function<Double>(Variable<Double>("lhs") + Keyword("+") +
    Variable<Double>("rhs")) { arguments, _, _  in
    guard let lhs = arguments["lhs"] as? Double,
        let rhs = arguments["rhs"] as? Double else { return nil }
    return lhs + rhs
}

private let min = Function<Double>(Keyword("min") + Keyword("(") + Variable<Double>("lhs") + Keyword(",") + Variable<Double>("rhs") + Keyword(")")) { arguments, _, _  in
        guard let lhs = arguments["lhs"] as? Double,
            let rhs = arguments["rhs"] as? Double else { return nil }
        return Swift.min(lhs, rhs)
}

private let max = Function<Double>(Keyword("max") + Keyword("(") + Variable<Double>("lhs") + Keyword(",") + Variable<Double>("rhs") + Keyword(")")) { arguments, _, _  in
    guard let lhs = arguments["lhs"] as? Double,
        let rhs = arguments["rhs"] as? Double else { return nil }
    return Swift.max(lhs, rhs)
}

private let foo = Function<Double>(Keyword("foo") + Keyword("(") + Keyword(")")) { arguments, _, _  in
    return Double.pi
}

private let foo2 = Function<Double>(Keyword("foo") + Keyword("(") + Variable<Double>("lhs") + Keyword(",") + Variable<Double>("rhs") + Keyword(")")) { arguments, _, _  in
    guard let lhs = arguments["lhs"] as? Double,
        let rhs = arguments["rhs"] as? Double else { return nil }
    return lhs - rhs
}

private let bar = Function<Double>(Keyword("bar") + Keyword("(") + Variable<Double>("value") + Keyword(")")) { arguments, _, _  in
    return  arguments["value"] as? Double ?? 0 - 2
}

private let parens = Function<Double>(Keyword("(") + Variable<Double>("value") + Keyword(")")) { arguments, _, _  in
    return arguments["value"] as? Double
}

let interpreter = TypedInterpreter(
    dataTypes: [number],
    functions: [multiplication, division, addition, min, max, foo, foo2, bar, parens]
)

func buildEvalExpressions(_ expressions: [String]) -> [() -> Double?] {
    return expressions.map { exp -> () -> Double? in
        return { interpreter.evaluate(exp) as? Double }
    }
}

func evaluateEvalExpressions(_ expressions: [() -> Double?]) -> Double? {
    var result: Double?
    expressions.forEach {
        result = $0()
    }
    return result
}

func evaluateEvalExpressions(_ expressions: [String]) -> Double? {
    return evaluateEvalExpressions(buildEvalExpressions(expressions))
}
