//
//  Expression.swift
//  Expression
//
//  Created by Nick Lockwood on 15/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

// MARK: Public interface

public class Expression {
    private let root: Subexpression
    private let evaluator: Evaluator

    /// Function prototype for evaluating an expression
    public typealias Evaluator = (_ symbol: Expression.Symbol, _ args: [Double]) throws -> Double?
    
    /// Symbols that make up an expression
    public enum Symbol: CustomStringConvertible {
        case variable(String)
        case infix(String)
        case prefix(String)
        case postfix(String)
        case function(String)
        
        public var name: String {
            switch self {
            case .variable(let string),
                 .infix(let string),
                 .prefix(let string),
                 .postfix(let string),
                 .function(let string):
                return string
            }
        }
        
        public var description: String {
            switch self {
            case .variable:
                return "variable `\(name)`"
            case .infix:
                return "infix operator `\(name)`"
            case .prefix:
                return "prefix operator `\(name)`"
            case .postfix:
                return "postfix operator `\(name)`"
            case .function:
                return "function `\(name)()`"
            }
        }
    }
    
    /// Runtime error when parsing or evaluating an expression
    public enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedToken(String)
        case missingDelimiter(String)
        case undefinedSymbol(Expression.Symbol)

        public var description: String {
            switch self {
            case .unexpectedToken(let string):
                return "Unexpected token `\(string)`"
            case .missingDelimiter(let string):
                return "Missing `\(string)`"
            case .undefinedSymbol(let symbol):
                return "Undefined \(symbol)"
            }
        }
    }
    
    /// Default constructor - creates an Expression object from a string
    public init(_ expression: String, evaluator: @escaping Evaluator = { _ in nil }) throws {
        var characters = expression.characters
        root = try characters.parseSubexpression()
        self.evaluator = evaluator
    }
    
    /// Evaluate the expression using an optional custom evaluator
    public func evaluate(_ evaluator: @escaping Evaluator = { _ in nil }) throws -> Double {
        return try root.evaluate { symbol, args in
            return try
                evaluator(symbol, args) ??
                self.evaluator(symbol, args) ??
                defaultEvaluator(symbol, args)
        }
    }
    
    /// Evaluate the expression using a dictionary of variables
    public func evaluate(_ variables: [String: Double]) throws -> Double {
        return try evaluate { symbol, _ in
            if case Symbol.variable(let name) = symbol {
                return variables[name]
            }
            return nil
        }
    }
    
    // Default evaluator for numeric arguments
    private func defaultEvaluator(_ symbol: Expression.Symbol, _ args: [Double]) throws -> Double? {
        switch symbol {
        
        // MARK: constants
        case .variable("π"):
            return .pi
            
        // MARK: infix operators
        case .infix("+"):
            return args[0] + args[1]
        case .infix("-"):
            return args[0] - args[1]
        case .infix("*"):
            return args[0] * args[1]
        case .infix("/"):
            return args[0] / args[1]
        case .infix("%"):
            return fmod(args[0], args[1])
            
        // MARK: prefix operators
        case .prefix("-"):
            return -args[0]
        case .prefix("√"):
            return sqrt(args[0])
        case .prefix("∛"):
            return pow(args[0], 1/3)
        case .prefix("∜"):
            return pow(args[0], 1/4)
            
        // MARK: functions (
        case .function(let name):
            
            // arity: 1
            if args.count == 1 {
                switch name {
                case "sqrt":
                    return sqrt(args[0])
                case "floor":
                    return floor(args[0])
                case "ceil":
                    return ceil(args[0])
                case "round":
                    return round(args[0])
                case "cos":
                    return cos(args[0])
                case "acos":
                    return acos(args[0])
                case "sin":
                    return sin(args[0])
                case "asin":
                    return asin(args[0])
                case "tan":
                    return tan(args[0])
                case "atan":
                    return atan(args[0])
                case "abs":
                    return abs(args[0])
                default:
                    break
                }
            }
            
            // arity: 2
            if args.count == 2 {
                switch name {
                case "pow":
                    return pow(args[0], args[1])
                case "max":
                    return max(args[0], args[1])
                case "min":
                    return min(args[0], args[1])
                case "atan":
                    return atan2(args[0], args[1])
                case "mod":
                    return fmod(args[0], args[1])
                default:
                    break
                }
            }
            
        default:
            break
        }
        
        // the buck stops here
        return nil
    }
}

// MARK: Parser

fileprivate enum Subexpression {
    case literal(String)
    case operand(Expression.Symbol, [Subexpression])
    case `operator`(String)
    
    func evaluate(_ evaluator: Expression.Evaluator) throws -> Double {
        switch self {
        case .literal(let value):
            if let value = Double(value) {
                return value
            }
            throw Expression.Error.unexpectedToken(value)
        case .operand(let symbol, let args):
            let argValues = try args.map { try $0.evaluate(evaluator) }
            if let value = try evaluator(symbol, argValues) {
                return value
            }
            throw Expression.Error.undefinedSymbol(symbol)
        case .operator(let name):
            throw Expression.Error.unexpectedToken(name)
        }
    }
}

fileprivate extension String.CharacterView {
    
    mutating func scanCharacters(_ matching: (Character) -> Bool) -> String? {
        var index = endIndex
        for (i, c) in enumerated() {
            if !matching(c) {
                index = self.index(startIndex, offsetBy: i)
                break
            }
        }
        if index > startIndex {
            let string = String(prefix(upTo: index))
            self = suffix(from: index)
            return string
        }
        return nil
    }
    
    mutating func scanCharacter(_ matching: (Character) -> Bool) -> String? {
        if let c = first, matching(c) {
            self = suffix(from: index(after: startIndex))
            return String(c)
        }
        return nil
    }
    
    mutating func scanCharacter(_ character: Character) -> Bool {
        return scanCharacter({ $0 == character }) != nil
    }
    
    mutating func skipWhitespace() -> Bool {
        while let c = first {
            switch c {
            case " ", "\t", "\n", "\r", "\r\n":
                self = suffix(from: index(after: startIndex))
            default:
                return true // more to parse
            }
        }
        return false // end of input
    }
    
    mutating func parseNumericLiteral() -> Subexpression? {
        
        func scanInteger() -> String? {
            return scanCharacters {
                if case "0" ... "9" = $0 {
                    return true
                }
                return false
            }
        }
        
        var number = ""
        if let integer = scanInteger() {
            number = integer
            let endOfInt = self
            if scanCharacter(".") {
                if let fraction = scanInteger() {
                    number += "." + fraction
                } else {
                    self = endOfInt
                }
            }
            let endOfFloat = self
            if let e = scanCharacter({ $0 == "e" || $0 == "E" }) {
                let sign = scanCharacter({ $0 == "-" || $0 == "+" }) ?? ""
                if let exponent = scanInteger() {
                    number += e + sign + exponent
                } else {
                    self = endOfFloat
                }
            }
            return .literal(number)
        }
        return nil
    }
    
    mutating func parseOperator() -> Subexpression? {
        if let op = scanCharacter({ "(),+-*/\\=!%°^&|<>?~±‡≤≥÷√∛∜".characters.contains($0) }) {
            return .operator(op)
        }
        return nil
    }
    
    mutating func parseIdentifier() -> Subexpression? {
        
        func isHead(_ c: Character) -> Bool {
            switch c {
            case "a" ... "z", "A" ... "Z", "_", "$", "#", "@", "π":
                return true
            default:
                return false
            }
        }
        
        func isTail(_ c: Character) -> Bool {
            switch c {
            case "a" ... "z", "A" ... "Z", "_", "0" ... "9":
                return true
            default:
                return false
            }
        }
        
        func scanIdentifier() -> String? {
            if let head = scanCharacter(isHead) {
                if let tail = scanCharacters(isTail) {
                    return head + tail
                }
                return head
            }
            return nil
        }
        
        if let identifier = scanIdentifier() {
            return .operand(.variable(identifier), [])
        }
        return nil
    }
    
    mutating func parseSubexpression() throws -> Subexpression {
        var stack: [Subexpression] = []
        var scopes: [[Subexpression]] = []
        
        func canBePrefix(_ op: String) -> Bool {
            return "-&√∛∜".contains(op)
        }
        
        func precedence(_ op: String) -> Int {
            switch op {
            case "*", "/":
                return 2
            case ",":
                return -1
            default:
                return 1
            }
        }
        
        func collapseStack(from i: Int) throws {
            guard stack.count > 1 else {
                return
            }
            let lhs = stack[i]
            switch lhs {
            case .operator(let symbol):
                guard canBePrefix(symbol) else {
                    // expression cannot start with a non-prefix operator
                    throw Expression.Error.unexpectedToken(symbol)
                }
                switch stack[i + 1] {
                case .operator:
                    // nested prefix operator?
                    try collapseStack(from: i + 1)
                    return
                case .literal, .operand:
                    // prefix operator
                    stack[i ... i + 1] = [.operand(.prefix(symbol), [stack[i + 1]])]
                    try collapseStack(from: 0)
                    return
                }
            case .literal, .operand:
                switch stack[i + 1] {
                case .literal(let value):
                    // literal cannot follow an operand
                    throw Expression.Error.unexpectedToken(String(value))
                case .operand(let symbol, _):
                    if case .variable(let name) = symbol {
                        // treat as a postfix operator
                        stack[i ... i + 1] = [.operand(.postfix(name), [stack[i]])]
                        try collapseStack(from: 0)
                        return
                    }
                    // operand cannot follow another operand
                    // TODO: the symbol may not be the first part of the operand
                    throw Expression.Error.unexpectedToken(symbol.name)
                case .operator(let op1):
                    if stack.count == i + 2 {
                        // postfix operator
                        stack[i ... i + 1] = [.operand(.postfix(op1), [lhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    let rhs = stack[i + 2]
                    if case .operator(let op3) = rhs {
                        if stack.count > i + 3 && canBePrefix(op3) {
                            guard case .operator = stack[i + 3] else {
                                // treat as prefix operator
                                try collapseStack(from: i + 2)
                                return
                            }
                        }
                        // postfix operator
                        stack[i ... i + 1] = [.operand(.postfix(op1), [lhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    // rhs is an operand
                    guard stack.count > i + 3 else {
                        // infix operator
                        stack[i ... i + 2] = [.operand(.infix(op1), [lhs, rhs])]
                        try collapseStack(from: 0)
                        return
                    }
                    switch stack[i + 3] {
                    case .operator(let op2):
                        if stack.count > i + 4 {
                            switch stack[i + 4] {
                            case .literal, .operand:
                                //infix operator
                                if precedence(op1) >= precedence(op2) {
                                    stack[i ... i + 2] = [.operand(.infix(op1), [lhs, rhs])]
                                    try collapseStack(from: 0)
                                    return
                                }
                            default:
                                break
                            }
                        }
                    default:
                        break
                    }
                    try collapseStack(from: i + 2)
                    return
                }
            }
        }
        
        
        while skipWhitespace(),
            let expression =
                parseNumericLiteral() ??
                parseOperator() ??
                parseIdentifier() {
            
            switch expression {
            case .operator("("):
                scopes.append(stack)
                stack = []
            case .operator(")"):
                try collapseStack(from: 0)
                guard var oldStack = scopes.last else {
                    throw Expression.Error.unexpectedToken(")")
                }
                scopes.removeLast()
                if let previous = oldStack.last {
                    if case .operand(.variable(let name), _) = previous {
                        // function call
                        oldStack.removeLast()
                        if stack.count > 0 {
                            // unwrap comma-delimited expression
                            while case .operand(.infix(","), let args) = stack.last! {
                                stack = args + stack.dropFirst()
                            }
                        }
                        stack = [.operand(.function(name), stack)]
                    }
                }
                stack = oldStack + stack
            default:
                stack.append(expression)
            }
        }
        if let junk = scanCharacters({
            switch $0 {
            case " ", "\t", "\n", "\r", "\r\n":
                return false
            default:
                return true
            }
        }) {
            // Unexpected token
            throw Expression.Error.unexpectedToken(junk)
        }
        if stack.count < 1 {
            // Empty expression
            throw Expression.Error.unexpectedToken("")
        }
        try collapseStack(from: 0)
        if scopes.count > 0 {
            throw Expression.Error.missingDelimiter(")")
        }
        return stack[0]
    }
}
