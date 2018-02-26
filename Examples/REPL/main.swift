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

// Previously defined variables
private var variables = [String: Any]()

while true {
    print("> ", terminator: "")
    guard var input = readLine() else { break }
    for c in 63232 ... 63235 {
        input = input.replacingOccurrences(of: String(UnicodeScalar(c)!), with: "")
    }
    var variable: String?
    var parsed = Expression.parse(input)
    if parsed.symbols.contains(where: { $0 == .infix("=") || $0 == .prefix("=") }) {
        let range = input.range(of: " = ") ?? input.range(of: "= ") ?? input.range(of: "=")!
        let identifier = input[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
        guard Expression.isValidIdentifier(identifier) else {
            print("error: Invalid variable name '\(identifier)'")
            continue
        }
        variable = identifier
        parsed = Expression.parse(String(input[range.upperBound...]))
    }
    let expression = AnyExpression(parsed, constants: variables)
    do {
        let value: Any = try expression.evaluate()
        if let variable = variable {
            variables[variable] = value
        }
        print(AnyExpression.stringify(value))
    } catch {
        print("error: \(error)")
    }
}
