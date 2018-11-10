//
//  main.swift
//  REPL
//
//  Created by Nick Lockwood on 23/02/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// Prevent control characters confusing expression
private let start = UnicodeScalar(63232)!
private let end = UnicodeScalar(63235)!
private let cursorCharacters = CharacterSet(charactersIn: start ... end)

class BoxedValue {
    var value: Any
    init(_ value: Any) {
        self.value = value
    }
}

// Previously defined variables
private var variables = [String: BoxedValue]()

func evaluate(_ input: String) throws -> Any {
    return try AnyExpression(
        Expression.parse(input), impureSymbols: { symbol in
            // look up symbol in stdlib
            if let fn = Expression.mathSymbols[symbol] ?? Expression.boolSymbols[symbol] {
                return { args in
                    try fn(args.map {
                        let unboxed = ($0 as? BoxedValue)?.value ?? $0
                        guard let number = (unboxed as? NSNumber) else {
                            throw Expression.Error.typeMismatch(symbol, args)
                        }
                        return Double(truncating: number)
                    })
                }
            }
            // handle variable assignment and retrieval
            switch symbol {
            case .infix("="):
                return { args in
                    guard let boxedValue = args[0] as? BoxedValue else {
                        throw Expression.Error.message("Left operand of = expression must be an lvalue")
                    }
                    boxedValue.value = args[1]
                    return args[1]
                }
            case let .variable(name):
                return { _ in
                    if let value = variables[name] {
                        return value
                    }
                    let newValue = BoxedValue(Any?.none as Any)
                    variables[name] = newValue
                    return newValue
                }
            default:
                return nil
            }
        }).evaluate()
}

while true {
    print("> ", terminator: "")
    guard var input = readLine() else { break }
    input = String(input.unicodeScalars.filter { !cursorCharacters.contains($0) })
    do {
        var value = try evaluate(input)
        if let boxedValue = value as? BoxedValue {
            value = boxedValue.value
        }
        print(AnyExpression.stringify(value))
    } catch {
        print("error: \(error)")
    }
}
