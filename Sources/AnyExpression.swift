//
//  AnyExpression.swift
//  Expression
//
//  Version 0.11.0
//
//  Created by Nick Lockwood on 18/04/2017.
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// Wrapper for Expression that works with any type of value
public struct AnyExpression: CustomStringConvertible {
    private let expression: Expression
    private let evaluator: () throws -> Any

    /// Function prototype for evaluating an expression
    /// Return nil for an unrecognized symbol, or throw an error if the symbol is recognized
    /// but there is some other problem (e.g. wrong number or type of arguments)
    public typealias Evaluator = (_ symbol: Symbol, _ args: [Any]) throws -> Any?

    /// Evaluator for individual symbols
    public typealias SymbolEvaluator = (_ args: [Any]) throws -> Any

    /// Symbols that make up an expression
    public typealias Symbol = Expression.Symbol

    /// Runtime error when parsing or evaluating an expression
    public typealias Error = Expression.Error

    /// Options for configuring an expression
    public typealias Options = Expression.Options

    /// Creates an Expression object from a string
    /// Optionally accepts some or all of:
    /// - A set of options for configuring expression behavior
    /// - A dictionary of constants for simple static values (including arrays)
    /// - A dictionary of symbols, for implementing custom functions and operators
    /// - A custom evaluator function for more complex symbol processing
    public init(
        _ expression: String,
        options: Options = .boolSymbols,
        constants: [String: Any] = [:],
        symbols: [Symbol: SymbolEvaluator] = [:],
        evaluator: Evaluator? = nil
    ) {
        self.init(
            Expression.parse(expression),
            options: options,
            constants: constants,
            symbols: symbols,
            evaluator: evaluator
        )
    }

    /// Alternative constructor that accepts a pre-parsed expression
    public init(
        _ expression: ParsedExpression,
        options: Options = .boolSymbols,
        constants: [String: Any] = [:],
        symbols: [Symbol: SymbolEvaluator] = [:],
        evaluator: Evaluator? = nil
    ) {
        let mask = (-Double.nan).bitPattern

        var values = [Any]()
        func store(_ value: Any) -> Double {
            switch value {
            case is Bool:
                break
            case let doubleValue as Double:
                return doubleValue
            case let floatValue as Float:
                return Double(floatValue)
            case is Int, is UInt, is Int32, is UInt32:
                return Double(truncating: value as! NSNumber)
            case let uintValue as UInt64:
                if uintValue <= 9007199254740992 as UInt64 {
                    return Double(uintValue)
                }
            case let intValue as Int64:
                if intValue <= 9007199254740992 as Int64,
                    intValue >= -9223372036854775808 as Int64 {
                    return Double(intValue)
                }
            case let numberValue as NSNumber:
                // Hack to avoid losing type info for UIFont.Weight, etc
                if "\(value)".contains("rawValue") {
                    break
                }
                return Double(truncating: numberValue)
            default:
                break
            }
            var index: Int?
            if AnyExpression.isNil(value) {
                index = values.index(where: { AnyExpression.isNil($0) })
            } else if let lhs = value as? AnyHashable {
                index = values.index(where: { $0 as? AnyHashable == lhs })
            } else if let lhs = value as? [AnyHashable] {
                index = values.index(where: { ($0 as? [AnyHashable]).map { $0 == lhs } ?? false })
            }
            if index == nil {
                values.append(value)
                index = values.count - 1
            }
            return Double(bitPattern: UInt64(index! + 1) | mask)
        }
        func load(_ arg: Double) -> Any? {
            let bits = arg.bitPattern
            if bits & mask == mask {
                let index = Int(bits ^ mask) - 1
                if index >= 0, index < values.count {
                    return values[index]
                }
            }
            return nil
        }

        // Handle string literals and constants
        var numericConstants = [String: Double]()
        var arrayConstants = [String: [Double]]()
        var pureSymbols = [Symbol: ([Double]) throws -> Double]()
        var impureSymbols = [Symbol: ([Any]) throws -> Any]()
        for symbol in expression.symbols {
            switch symbol {
            case let .variable(name):
                if let value = constants[name] {
                    numericConstants[name] = store(value)
                } else if name.count >= 2, "'\"".contains(name.first!), name.last == name.first {
                    numericConstants[name] = store(String(name.dropFirst().dropLast()))
                } else if let fn = symbols[symbol] {
                    impureSymbols[symbol] = fn
                } else if name == "nil" {
                    numericConstants["nil"] = store(nil as Any? as Any)
                } else if name == "false" {
                    numericConstants["false"] = store(false)
                } else if name == "true" {
                    numericConstants["true"] = store(true)
                }
            case let .array(name):
                if let array = constants[name] as? [Any] {
                    arrayConstants[name] = array.map { store($0) }
                } else if let fn = symbols[symbol] {
                    impureSymbols[symbol] = fn
                }
            case .infix("??"):
                // Not sure why anyone would override this, but the option is there
                if let fn = symbols[symbol] {
                    impureSymbols[symbol] = fn
                    break
                }
                // Note: the ?? operator should be safe to inline, as it doesn't store any
                // values, but symbols which store values cannot be safely inlined since they
                // are potentially side-effectful, which is why they are currently declared
                // in the evaluator function below instead of here
                pureSymbols[symbol] = { args in
                    let lhs = args[0]
                    return load(lhs).map { AnyExpression.isNil($0) ? args[1] : lhs } ?? lhs
                }
            // TODO: literal string as function (formatted string)?
            default:
                if let fn = symbols[symbol] {
                    impureSymbols[symbol] = fn
                }
            }
        }

        // These are constant values that won't change between evaluations
        // and won't be re-stored, so must not be cleared
        let literals = values

        // Set description based on the parsed expression, prior to
        // peforming optimizations. This avoids issues with inlined
        // constants and string literals being converted to `nan`
        description = expression.description

        // Build Expression
        let expression = Expression(expression,
                                    options: options
                                        .subtracting(.boolSymbols)
                                        .union(.pureSymbols),
                                    constants: numericConstants,
                                    arrays: arrayConstants,
                                    symbols: pureSymbols) { symbol, args in
            var stored = false
            let anyArgs: [Any] = args.map {
                if let value = load($0) {
                    stored = true
                    return value
                }
                return $0
            }
            if let value = try impureSymbols[symbol]?(anyArgs) ?? evaluator?(symbol, anyArgs) {
                return store(value)
            }
            func doubleArgs() throws -> [Double]? {
                guard stored else {
                    return args
                }
                var doubleArgs = [Double]()
                for arg in anyArgs {
                    guard let doubleValue = arg as? Double ?? (arg as? NSNumber).map({
                        return Double(truncating: $0)
                    }) else {
                        _ = try AnyExpression.unwrap(arg)
                        return nil
                    }
                    doubleArgs.append(doubleValue)
                }
                return doubleArgs
            }
            if let fn = Expression.mathSymbols[symbol] {
                if let args = try doubleArgs() {
                    // The arguments are all numbers, but we're going to
                    // potentially lose precision by converting them to doubles
                    // TODO: find alternative approach that doesn't lose precision
                    return stored ? try fn(args) : nil
                } else if case .infix("+") = symbol {
                    switch try (AnyExpression.unwrap(anyArgs[0]), AnyExpression.unwrap(anyArgs[1])) {
                    case let (lhs as String, rhs):
                        return try store("\(lhs)\(AnyExpression.stringify(rhs))")
                    case let (lhs, rhs as String):
                        return try store("\(AnyExpression.stringify(lhs))\(rhs)")
                    default:
                        break
                    }
                }
            } else if options.contains(.boolSymbols), let fn = Expression.boolSymbols[symbol] {
                switch symbol {
                case .infix("==") where !(anyArgs[0] is Double) || !(anyArgs[1] is Double):
                    return store(args[0].bitPattern == args[1].bitPattern)
                case .infix("!=") where !(anyArgs[0] is Double) || !(anyArgs[1] is Double):
                    return store(args[0].bitPattern != args[1].bitPattern)
                case .infix("?:"):
                    guard anyArgs.count == 3 else {
                        return nil
                    }
                    if let number = anyArgs[0] as? NSNumber {
                        return Double(truncating: number) != 0 ? args[1] : args[2]
                    }
                default:
                    if let args = try doubleArgs() {
                        // Use Expression Bool functions, but convert results to actual Bools
                        // See note above about precision
                        return try store(fn(args) != 0)
                    }
                }
            } else {
                // Fall back to Expression symbol handler
                return nil
            }
            throw Error.message("\(symbol) cannot be used with arguments of type (\(anyArgs.map { "\(type(of: $0))" }.joined(separator: ", ")))")
        }
        self.evaluator = {
            defer { values = literals }
            let value = try expression.evaluate()
            return load(value) ?? value
        }
        self.expression = expression
    }

    /// Evaluate the expression
    public func evaluate<T>() throws -> T {
        guard let value: T = try AnyExpression.cast(evaluator()) else {
            throw Error.message("Unexpected nil return value")
        }
        return value
    }

    /// All symbols used in the expression
    public var symbols: Set<Symbol> {
        return expression.symbols
    }

    /// Returns the optmized, pretty-printed expression if it was valid
    /// Otherwise, returns the original (invalid) expression string
    public let description: String
}

// Private API
private extension AnyExpression {

    // Convert any object to a string
    static func stringify(_ value: Any) throws -> String {
        switch try unwrap(value) {
        case let bool as Bool:
            return bool ? "true" : "false"
        case let number as NSNumber:
            if let int = Int64(exactly: number) {
                return "\(int)"
            }
            if let uint = UInt64(exactly: number) {
                return "\(uint)"
            }
            return "\(number)"
        case let value:
            return "\(value)"
        }
    }

    // Cast a value
    static func cast<T>(_ anyValue: Any) throws -> T? {
        if let value = anyValue as? T {
            return value
        }
        switch T.self {
        case let type as _Optional.Type where anyValue is NSNull:
            return type.nullValue as? T
        case is Double.Type, is Optional<Double>.Type:
            if let value = anyValue as? NSNumber {
                return Double(truncating: value) as? T
            }
        case is Int.Type, is Optional<Int>.Type:
            if let value = anyValue as? NSNumber {
                return Int(truncating: value) as? T
            }
        case is Bool.Type, is Optional<Bool>.Type:
            if let value = anyValue as? NSNumber {
                return (Double(truncating: value) != 0) as? T
            }
        case is String.Type:
            return try stringify(anyValue) as? T
        default:
            break
        }
        if isNil(anyValue) {
            return nil
        }
        throw AnyExpression.Error.message("Return type mismatch: \(type(of: anyValue)) is not compatible with \(T.self)")
    }

    // Unwraps a potentially optional value or throws if nil
    static func unwrap(_ value: Any) throws -> Any {
        switch value {
        case let optional as _Optional:
            guard let value = optional.value else {
                fallthrough
            }
            return try unwrap(value)
        case is NSNull:
            throw AnyExpression.Error.message("Unexpected nil value")
        default:
            return value
        }
    }

    // Test if a value is nil
    static func isNil(_ value: Any) -> Bool {
        if let optional = value as? _Optional {
            guard let value = optional.value else {
                return true
            }
            return isNil(value)
        }
        return value is NSNull
    }
}

// Used to test if a value is Optional
private protocol _Optional {
    var value: Any? { get }
    static var nullValue: Any { get }
}

extension Optional: _Optional {
    fileprivate var value: Any? { return self }
    static var nullValue: Any { return none as Any }
}

extension ImplicitlyUnwrappedOptional: _Optional {
    fileprivate var value: Any? { return self }
    static var nullValue: Any { return none as Any }
}
