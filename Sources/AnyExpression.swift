//
//  AnyExpression.swift
//  Expression
//
//  Version 0.12.3
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
    private let describer: () -> String
    private let evaluator: () throws -> Any

    /// Evaluator for individual symbols
    public typealias SymbolEvaluator = (_ args: [Any]) throws -> Any

    /// Symbols that make up an expression
    public typealias Symbol = Expression.Symbol

    /// Runtime error when parsing or evaluating an expression
    public typealias Error = Expression.Error

    /// Options for configuring an expression
    public typealias Options = Expression.Options

    /// Creates an AnyExpression instance from a string
    /// Optionally accepts some or all of:
    /// - A set of options for configuring expression behavior
    /// - A dictionary of constants for simple static values (including arrays)
    /// - A dictionary of symbols, for implementing custom functions and operators
    public init(
        _ expression: String,
        options: Options = .boolSymbols,
        constants: [String: Any] = [:],
        symbols: [Symbol: SymbolEvaluator] = [:]
    ) {
        self.init(
            Expression.parse(expression),
            options: options,
            constants: constants,
            symbols: symbols
        )
    }

    /// Alternative constructor that accepts a pre-parsed expression
    public init(
        _ expression: ParsedExpression,
        options: Options = [],
        constants: [String: Any] = [:],
        symbols: [Symbol: SymbolEvaluator] = [:]
    ) {
        // Options
        let pureSymbols = options.contains(.pureSymbols)

        self.init(
            expression,
            options: options,
            impureSymbols: { symbol in
                switch symbol {
                case let .variable(name), let .array(name):
                    // TODO: should an unmatched array lookup fall back to variable?
                    if constants[name] == nil, let fn = symbols[symbol] {
                        return fn
                    }
                default:
                    if !pureSymbols, let fn = symbols[symbol] {
                        return fn
                    }
                }
                return nil
            },
            pureSymbols: { symbol in
                switch symbol {
                case let .variable(name):
                    if let value = constants[name] {
                        return { _ in value }
                    }
                case let .array(name):
                    guard let value = constants[name] else {
                        return nil
                    }
                    return AnyExpression.arrayEvaluator(for: symbol, value)
                default:
                    return symbols[symbol]
                }
                return nil
            }
        )
    }

    /// Alternative constructor for advanced usage
    /// Allows for dynamic symbol lookup or generation without any performance overhead
    /// Note that standard library symbols are all enabled by default - to disable them
    /// return `{ _ in throw AnyExpression.Error.undefinedSymbol(symbol) }` from your lookup function
    public init(
        _ expression: ParsedExpression,
        impureSymbols: (Symbol) -> SymbolEvaluator?,
        pureSymbols: (Symbol) -> SymbolEvaluator? = { _ in nil }
    ) {
        self.init(
            expression,
            options: .boolSymbols,
            impureSymbols: impureSymbols,
            pureSymbols: pureSymbols
        )
    }

    /// Alternative constructor with only pure symbols
    public init(_ expression: ParsedExpression, pureSymbols: (Symbol) -> SymbolEvaluator?) {
        self.init(expression, impureSymbols: { _ in nil }, pureSymbols: pureSymbols)
    }

    // Private initializer implementation
    private init(
        _ expression: ParsedExpression,
        options: Options,
        impureSymbols: (Symbol) -> SymbolEvaluator?,
        pureSymbols: (Symbol) -> SymbolEvaluator?
    ) {
        let box = NanBox()

        func loadNumber(_ arg: Double) -> Double? {
            return box.loadIfStored(arg).map { ($0 as? NSNumber).map { Double(truncating: $0) } } ?? arg
        }
        func equalArgs(_ lhs: Double, _ rhs: Double) throws -> Bool {
            switch (AnyExpression.unwrap(box.load(lhs)), AnyExpression.unwrap(box.load(rhs))) {
            case (nil, nil):
                return true
            case (nil, _), (_, nil):
                return false
            case let (lhs as Double, rhs as Double):
                return lhs == rhs
            case let (lhs as AnyHashable, rhs as AnyHashable):
                return lhs == rhs
            case let (lhs as [AnyHashable], rhs as [AnyHashable]):
                return lhs == rhs
            case let (lhs as [AnyHashable: AnyHashable], rhs as [AnyHashable: AnyHashable]):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable), rhs as (AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs?, rhs?):
                if type(of: lhs) == type(of: rhs) {
                    let symbol = Symbol.infix("==").description
                    throw Error.message("Arguments for \(symbol) must conform to the Hashable protocol")
                }
                throw Error.typeMismatch(.infix("=="), [lhs, rhs])
            }
        }
        func unwrapString(_ name: String) -> String? {
            guard name.count >= 2, "'\"".contains(name.first!) else {
                return nil
            }
            return String(name.dropFirst().dropLast())
        }

        // Set description based on the parsed expression, prior to
        // performing optimizations. This avoids issues with inlined
        // constants and string literals being converted to `nan`
        describer = { expression.description }

        // Options
        let boolSymbols = options.contains(.boolSymbols) ? Expression.boolSymbols : [:]
        let shouldOptimize = !options.contains(.noOptimize)

        // Evaluators
        func defaultEvaluator(for symbol: Symbol) -> Expression.SymbolEvaluator? {
            if let fn = Expression.mathSymbols[symbol] {
                switch symbol {
                case .infix("+"):
                    return { args in
                        switch (box.load(args[0]), box.load(args[1])) {
                        case let (lhs as String, any):
                            guard let rhs = AnyExpression.unwrap(any) else {
                                throw Error.typeMismatch(symbol, [lhs, any])
                            }
                            return box.store("\(lhs)\(AnyExpression.stringify(rhs))")
                        case let (any, rhs as String):
                            guard let lhs = AnyExpression.unwrap(any) else {
                                throw Error.typeMismatch(symbol, [any, rhs])
                            }
                            return box.store("\(AnyExpression.stringify(lhs))\(rhs)")
                        case let (lhs as Double, rhs as Double):
                            return lhs + rhs
                        case let (lhs as NSNumber, rhs as NSNumber):
                            return Double(truncating: lhs) + Double(truncating: rhs)
                        case let (lhs, rhs):
                            throw Error.typeMismatch(symbol, [lhs, rhs])
                        }
                    }
                case .variable, .function(_, arity: 0):
                    return fn
                default:
                    return { args in
                        // We potentially lose precision by converting all numbers to doubles
                        // TODO: find alternative approach that doesn't lose precision
                        try fn(args.map {
                            guard let doubleValue = loadNumber($0) else {
                                throw Error.typeMismatch(symbol, args.map(box.load))
                            }
                            return doubleValue
                        })
                    }
                }
            } else if let fn = boolSymbols[symbol] {
                switch symbol {
                case .variable("false"):
                    return { _ in NanBox.falseValue }
                case .variable("true"):
                    return { _ in NanBox.trueValue }
                case .infix("=="):
                    return { try equalArgs($0[0], $0[1]) ? NanBox.trueValue : NanBox.falseValue }
                case .infix("!="):
                    return { try equalArgs($0[0], $0[1]) ? NanBox.falseValue : NanBox.trueValue }
                case .infix("?:"):
                    return { args in
                        guard args.count == 3 else {
                            throw Error.undefinedSymbol(symbol)
                        }
                        if let number = loadNumber(args[0]) {
                            return number != 0 ? args[1] : args[2]
                        }
                        throw Error.typeMismatch(symbol, args.map(box.load))
                    }
                default:
                    return { args in
                        try fn(args.map {
                            guard let doubleValue = loadNumber($0) else {
                                throw Error.typeMismatch(symbol, args.map(box.load))
                            }
                            return doubleValue
                        }) == 0 ? NanBox.falseValue : NanBox.trueValue
                    }
                }
            } else {
                switch symbol {
                case .variable("nil"):
                    return { _ in NanBox.nilValue }
                case .infix("??"):
                    return { args in
                        let lhs = box.load(args[0])
                        return AnyExpression.isNil(lhs) ? args[1] : args[0]
                    }
                case .infix("[]"):
                    return { args in
                        let fn = AnyExpression.arrayEvaluator(for: symbol, box.load(args[0]))
                        return try box.store(fn([box.load(args[1])]))
                    }
                case .function("[]", _):
                    return { box.store($0.map(box.load)) }
                case let .variable(name):
                    guard let string = unwrapString(name) else {
                        return { _ in throw Error.undefinedSymbol(symbol) }
                    }
                    let stringRef = box.store(string)
                    return { _ in stringRef }
                case let .array(name):
                    guard let string = unwrapString(name) else {
                        return { _ in throw Error.undefinedSymbol(symbol) }
                    }
                    // TODO: should indexing of strings be allowed?
                    return { _ in throw Error.illegalSubscript(symbol, string) }
                default:
                    return nil
                }
            }
        }

        // Build Expression
        let expression = Expression(
            expression,
            impureSymbols: { symbol in
                if let fn = impureSymbols(symbol) {
                    return { try box.store(fn($0.map(box.load))) }
                } else if case let .array(name) = symbol, let fn = impureSymbols(.variable(name)) {
                    return { args in
                        let fn = AnyExpression.arrayEvaluator(for: symbol, try fn([]))
                        return try box.store(fn(args.map(box.load)))
                    }
                }
                if !shouldOptimize {
                    if let fn = pureSymbols(symbol) {
                        return { try box.store(fn($0.map(box.load))) }
                    }
                    return defaultEvaluator(for: symbol)
                }
                return nil
            },
            pureSymbols: { symbol in
                if let fn = pureSymbols(symbol) {
                    switch symbol {
                    case .variable, .function(_, arity: 0):
                        do {
                            let value = try box.store(fn([]))
                            return { _ in value }
                        } catch {
                            return { _ in throw error }
                        }
                    default:
                        return { try box.store(fn($0.map(box.load))) }
                    }
                } else if case let .array(name) = symbol, let fn = pureSymbols(.variable(name)) {
                    let evaluator: SymbolEvaluator
                    do {
                        evaluator = try AnyExpression.arrayEvaluator(for: symbol, fn([]))
                    } catch {
                        return { _ in throw error }
                    }
                    return { try box.store(evaluator($0.map(box.load))) }
                }
                guard let fn = defaultEvaluator(for: symbol) else {
                    if case let .function(name, _) = symbol {
                        for i in 0 ... 10 {
                            let symbol = Symbol.function(name, arity: .exactly(i))
                            if impureSymbols(symbol) ?? pureSymbols(symbol) != nil {
                                return { _ in throw Error.arityMismatch(symbol) }
                            }
                        }
                    }
                    return Expression.errorEvaluator(for: symbol)
                }
                return fn
            }
        )

        // These are constant values that won't change between evaluations
        // and won't be re-stored, so must not be cleared
        let literals = box.values

        // Evaluation isn't thread-safe due to shared values
        // so we use objc_sync_enter/exit to prevent re-entrancy
        evaluator = {
            objc_sync_enter(box)
            defer {
                box.values = literals
                objc_sync_exit(box)
            }
            let value = try expression.evaluate()
            return box.load(value)
        }
        self.expression = expression
    }

    /// Evaluate the expression
    public func evaluate<T>() throws -> T {
        let anyValue = try evaluator()
        guard let value: T = AnyExpression.cast(anyValue) else {
            if AnyExpression.isNil(anyValue) {
                // Fall through
            } else if T.self is String.Type || T.self is Optional<String>.Type {
                // TODO: should we stringify any type like this?
                return AnyExpression.stringify(anyValue) as! T
            } else if T.self is Bool.Type || T.self is Optional<Bool>.Type,
                let value = AnyExpression.cast(anyValue) as Double? {
                // TODO: should we boolify numeric types like this?
                return (value != 0) as! T
            } else if let boolValue = anyValue as? Bool,
                // TODO: should we numberify Bool values like this?
                let value: T = AnyExpression.cast(boolValue ? 1 : 0) {
                return value
            }
            throw Error.resultTypeMismatch(T.self, anyValue)
        }
        return value
    }

    /// All symbols used in the expression
    public var symbols: Set<Symbol> { return expression.symbols }

    /// Returns the optmized, pretty-printed expression if it was valid
    /// Otherwise, returns the original (invalid) expression string
    public var description: String { return describer() }
}

// MARK: Internal API

extension AnyExpression.Error {
    /// Standard error message for mismatched argument types
    static func typeMismatch(_ symbol: AnyExpression.Symbol, _ args: [Any]) -> AnyExpression.Error {
        let types = args.map {
            AnyExpression.stringify(AnyExpression.isNil($0) ? $0 : type(of: $0))
        }
        switch symbol {
        case .infix("[]") where types.count == 2:
            return .message("Attempted to subscript \(types[0]) with incompatible index type \(types[1])")
        case .array where types.count == 1:
            return .message("Attempted to subscript \(symbol.escapedName)[] with incompatible index type \(types[0])")
        case _ where types.count == 1:
            return .message("Argument of type \(types[0]) is not compatible with \(symbol)")
        default:
            return .message("Arguments of type (\(types.joined(separator: ", "))) are not compatible with \(symbol)")
        }
    }

    /// Standard error message for mismatched return type
    static func resultTypeMismatch(_ type: Any.Type, _ value: Any) -> AnyExpression.Error {
        let valueType = AnyExpression.stringify(AnyExpression.unwrap(value).map { Swift.type(of: $0) } as Any)
        return .message("Result type \(valueType) is not compatible with expected type \(AnyExpression.stringify(type))")
    }

    /// Standard error message for subscripting a non-array value
    static func illegalSubscript(_ symbol: AnyExpression.Symbol, _ value: Any) -> AnyExpression.Error {
        let type = AnyExpression.stringify(AnyExpression.unwrap(value).map { Swift.type(of: $0) } as Any)
        let value = symbol == .infix("[]") ? AnyExpression.stringify(value) : symbol.escapedName
        return .message("Attempted to subscript \(type) value \(value)")
    }
}

extension AnyExpression {
    // Cast a value to the specified type
    static func cast<T>(_ anyValue: Any) -> T? {
        if let value = anyValue as? T {
            return value
        }
        var type: Any.Type = T.self
        if let optionalType = type as? _Optional.Type {
            type = optionalType.wrappedType
        }
        switch type {
        case let numericType as _Numeric.Type:
            if anyValue is Bool { return nil }
            return (anyValue as? NSNumber).map { numericType.init(truncating: $0) } as? T
        case let arrayType as _Array.Type:
            return arrayType.cast(anyValue) as? T
        default:
            return nil
        }
    }

    // Convert any value to a printable string
    static func stringify(_ value: Any) -> String {
        switch value {
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
        case is Any.Type:
            let typeName = "\(value)"
            if typeName.hasPrefix("("), let range = typeName.range(of: " in") {
                let range = typeName.index(after: typeName.startIndex) ..< range.lowerBound
                return String(typeName[range])
            }
            return typeName
        case let value:
            return unwrap(value).map { "\($0)" } ?? "nil"
        }
    }

    // Unwraps a potentially optional value
    static func unwrap(_ value: Any) -> Any? {
        switch value {
        case let optional as _Optional:
            guard let value = optional.value else {
                fallthrough
            }
            return unwrap(value)
        case is NSNull:
            return nil
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

// MARK: Private API

private extension AnyExpression {
    // Value storage
    final class NanBox {
        private static let mask = (-Double.nan).bitPattern
        private static let indexOffset = 4
        private static let nilBits = bitPattern(for: -1)
        private static let falseBits = bitPattern(for: -2)
        private static let trueBits = bitPattern(for: -3)

        private static func bitPattern(for index: Int) -> UInt64 {
            assert(index > -indexOffset)
            return UInt64(index + indexOffset) | mask
        }

        // Literal values
        public static let nilValue = Double(bitPattern: nilBits)
        public static let trueValue = Double(bitPattern: trueBits)
        public static let falseValue = Double(bitPattern: falseBits)

        // The values stored in the box
        public var values = [Any]()

        // Store a value in the box
        public func store(_ value: Any) -> Double {
            switch value {
            case let doubleValue as Double:
                return doubleValue
            case let boolValue as Bool:
                return boolValue ? NanBox.trueValue : NanBox.falseValue
            case let floatValue as Float:
                return Double(floatValue)
            case is Int, is UInt, is Int32, is UInt32:
                return Double(truncating: value as! NSNumber)
            case let uintValue as UInt64:
                if uintValue <= 9007199254740992 as UInt64 {
                    return Double(uintValue)
                }
            case let intValue as Int64:
                if intValue <= 9007199254740992 as Int64, intValue >= -9223372036854775808 as Int64 {
                    return Double(intValue)
                }
            case let numberValue as NSNumber:
                // Hack to avoid losing type info for UIFont.Weight, etc
                if "\(value)".contains("rawValue") {
                    break
                }
                return Double(truncating: numberValue)
            case _ where AnyExpression.isNil(value):
                return NanBox.nilValue
            default:
                break
            }
            values.append(value)
            return Double(bitPattern: NanBox.bitPattern(for: values.count - 1))
        }

        // Retrieve a value from the box, if it exists
        func loadIfStored(_ arg: Double) -> Any? {
            switch arg.bitPattern {
            case NanBox.nilBits:
                return nil as Any? as Any
            case NanBox.trueBits:
                return true
            case NanBox.falseBits:
                return false
            case let bits:
                guard var index = Int(exactly: bits ^ NanBox.mask) else {
                    return nil
                }
                index -= NanBox.indexOffset
                return values.indices.contains(index) ? values[index] : nil
            }
        }

        // Retrieve a value if it exists, else return the argument
        func load(_ arg: Double) -> Any {
            return loadIfStored(arg) ?? arg
        }
    }

    // Array evaluator
    static func arrayEvaluator(for symbol: Symbol, _ value: Any) -> SymbolEvaluator {
        switch value {
        case let array as _Array:
            return { args in
                guard let index = AnyExpression.cast(args[0]) as Int? else {
                    throw symbol == .infix("[]") ?
                        Error.typeMismatch(symbol, [array, args[0]]) :
                        Error.typeMismatch(symbol, args)
                }
                guard let value = array.value(at: index) else {
                    throw Error.arrayBounds(symbol, Double(index))
                }
                return value
            }
        case let dictionary as _Dictionary:
            return { args in
                guard let value = dictionary.value(for: args[0]) else {
                    throw symbol == .infix("[]") ?
                        Error.typeMismatch(symbol, [dictionary, args[0]]) :
                        Error.typeMismatch(symbol, args)
                }
                return value
            }
        case let value:
            return { _ in
                throw Error.illegalSubscript(symbol, value)
            }
        }
    }

    // Cast an array
    static func arrayCast<T>(_ anyValue: Any) -> [T]? {
        guard let array = anyValue as? [Any] else {
            return nil
        }
        var value = [T]()
        for element in array {
            guard let element: T = cast(element) else {
                return nil
            }
            value.append(element)
        }
        return value
    }
}

// Used for casting numeric values
private protocol _Numeric {
    init(truncating: NSNumber)
}

extension Int: _Numeric {}
extension Int8: _Numeric {}
extension Int16: _Numeric {}
extension Int32: _Numeric {}
extension Int64: _Numeric {}

extension UInt: _Numeric {}
extension UInt8: _Numeric {}
extension UInt16: _Numeric {}
extension UInt32: _Numeric {}
extension UInt64: _Numeric {}

extension Double: _Numeric {}
extension Float: _Numeric {}

// Used for subscripting array values
private protocol _Array {
    func value(at index: Int) -> Any?
    static func cast(_ value: Any) -> Any?
}

extension Array: _Array {
    func value(at index: Int) -> Any? {
        guard indices.contains(index) else {
            return nil // Out of bounds
        }
        return self[index]
    }

    static func cast(_ value: Any) -> Any? {
        return AnyExpression.arrayCast(value) as [Element]?
    }
}

extension ArraySlice: _Array {
    func value(at index: Int) -> Any? {
        guard indices.contains(index) else {
            return nil // Out of bounds
        }
        return self[index]
    }

    static func cast(_ value: Any) -> Any? {
        return (AnyExpression.arrayCast(value) as [Element]?).map(self.init)
    }
}

// Used for subscripting dictionary values
private protocol _Dictionary {
    func value(for key: Any) -> Any?
}

extension Dictionary: _Dictionary {
    func value(for key: Any) -> Any? {
        guard let key = AnyExpression.cast(key) as Key? else {
            return nil // Type mismatch
        }
        return self[key] as Any
    }
}

// Used to test if a value is Optional
private protocol _Optional {
    var value: Any? { get }
    static var wrappedType: Any.Type { get }
}

extension Optional: _Optional {
    fileprivate var value: Any? { return self }
    fileprivate static var wrappedType: Any.Type { return Wrapped.self }
}

extension ImplicitlyUnwrappedOptional: _Optional {
    fileprivate var value: Any? { return self }
    fileprivate static var wrappedType: Any.Type { return Wrapped.self }
}
