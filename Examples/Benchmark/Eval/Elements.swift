/*
 *  Copyright (c) 2018 Laszlo Teveli.
 *
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

import Foundation

/// `MatchElement`s are used by `Matcher` instances to be able to recognise patterns.
/// Currently, the two main kind of `MatchElement` classes are `Keyword`s and `Variable`s
public protocol PatternElement {
    /// Using this method, an element returns how much the String provided in the `prefix` parameter matches the current element
    /// - parameter prefix: The input
    /// - parameter options: Options that modify the matching algorithm
    /// - returns: The result of the match operation
    func matches(prefix: String, options: PatternOptions) -> MatchResult<Any>
}

/// `Keyword` instances are used to provide static points in match sequences so that they can be used as pillars of the expressions the developer tries to match
public class Keyword: PatternElement, Equatable {
    /// The type of the Keyword determines whether the item holds some special purpose, or it's just an ordinary static String
    public enum KeywordType: Equatable {
        /// By default, `Keyword` is created as a generic type, meaning, that there is no special requirement, that they need to fulfil
        case generic
        /// If a pattern contains two, semantically paired `Keyword`s, they often represent opening and closing parentheses or any special enclosing characters.
        /// This case represents the first one of the pair, needs to be matched. Often these are expressed as opening parentheses, e.g. `(`
        case openingStatement
        /// If a pattern contains two, semantically paired `Keyword`s, they often represent opening and closing parentheses or any special enclosing characters.
        /// This case represents the second (and last) one of the pair, needs to be matched. Often these are expressed as closing parentheses, e.g. `)`
        case closingStatement
    }

    /// Name (and value) of the `Keyword`
    let name: String

    /// Type of the keyword, which gives the framework some extra semantics about its nature
    let type: KeywordType

    /// `Keyword` initialiser
    /// - parameter name: The name (and value) of the `Keyword`
    /// - parameter type: Type of the keyword, which gives the framework some extra semantics about its nature. Defaults to `KeywordType.generic`
    public init(_ name: String, type: KeywordType = .generic) {
        self.name = name.trim()
        self.type = type
    }

    /// `Keyword` instances are returning exactMatch, when they are equal to the `prefix` input.
    /// If the input is really just a prefix of the keyword, possible metch is returned. noMatch otherwise.
    /// - parameter prefix: The input
    /// - parameter options: Options that modify the matching algorithm
    /// - returns: The result of the match operation
    public func matches(prefix: String, options: PatternOptions = []) -> MatchResult<Any> {
        let checker = options.contains(.backwardMatch) ? String.hasSuffix : String.hasPrefix
        if name == prefix || checker(prefix)(name) {
            return .exactMatch(length: name.count, output: name, variables: [:])
        } else if checker(name)(prefix) {
            return .possibleMatch
        }
        return .noMatch
    }

    /// `Keyword` instances are `Equatable`s
    /// - parameter lhs: Left hand side
    /// - parameter rhs: Right hand side
    /// - returns: Whether the names and types are equal in `lhs` and `rhs`
    public static func == (lhs: Keyword, rhs: Keyword) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type
    }
}

/// A special subclass of the `Keyword` class, which initialises a `Keyword` with an opening type.
/// Usually used for opening parentheses: `OpenKeyword("[")`
public class OpenKeyword: Keyword {
    /// The initialiser uses the opening type, but the `name` still must be provided
    /// - parameter name: The name (and value) of the `Keyword`
    public init(_ name: String) {
        super.init(name, type: .openingStatement)
    }
}

/// A special subclass of the `Keyword` class, which initialises a `Keyword` with an closing type.
/// Usually used for closing parentheses: `CloseKeyword("]")`
public class CloseKeyword: Keyword {
    /// The initialiser uses the closing type, but the `name` still must be provided
    /// - parameter name: The name (and value) of the `Keyword`
    public init(_ name: String) {
        super.init(name, type: .closingStatement)
    }
}

/// Options that modify the behaviour of the variable matching, and the output that the framework provides
public struct VariableOptions: OptionSet {
    /// Integer representation of the option
    public let rawValue: Int
    /// Basic initialiser with the integer representation
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// If set, the value of the recognised placeholder will not be processed. Otherwise, it will be evaluated, using the `interpreterForEvaluatingVariables` property of the interpreter instance
    public static let notInterpreted: VariableOptions = VariableOptions(rawValue: 1 << 0)
    /// Whether the processed variable should be or not to be trimmed (removing whitespaces from both sides)
    public static let notTrimmed: VariableOptions = VariableOptions(rawValue: 1 << 1)
    /// Provides information whether the match should be exhaustive or just use the shortest possible matching string (even zero characters in some edge cases). This depends on the surrounding `Keyword` instances in the containing collection.
    public static let exhaustiveMatch: VariableOptions = VariableOptions(rawValue: 1 << 2)
    /// If interpreted and the result of the evaluation is `nil`, then `acceptsNilValue` determines if the current match result should be instant noMatch, or `nil` is an accepted value, so the matching should be continued
    public static let acceptsNilValue: VariableOptions = VariableOptions(rawValue: 1 << 3)

    /// In order to avoid double negatives in the source code (e.g. !notInterpreted), this helper checks the lack of .notInterpreted value in the optionset
    var interpreted: Bool { return !contains(.notInterpreted) }
    /// In order to avoid double negatives in the source code (e.g. !notTrimmed), this helper checks the lack of .notTrimmed value in the optionset
    var trimmed: Bool { return !contains(.notTrimmed) }
}

/// Protocol for all Variables
internal protocol VariableProtocol {
    /// Unique identifier of the variable that is used when matching and returning them in the matcher.
    var name: String { get }
    /// Options that modify the behaviour of the variable matching, and the output that the framework provides
    var options: VariableOptions { get }
    /// The result of the evaluated variable will be ran through this map function, transforming its value. By default the map tries to convert the matched value to the expected type, using the `as?` operator.
    /// - parameter input: The first parameter is the value is going to be transformed
    /// - parameter interpreter: Helps the mapper function to parse and interpret the contents
    /// - returns: The transformed value or nil - if the value was validated with a negative result
    func performMap(input: Any, interpreter: Any) -> Any?
}

/// Generic superclass of `Variable`s which are aware of their `Interpreter` classes,
/// as they use it when mapping their values
public class GenericVariable<T, E: Interpreter> : VariableProtocol, PatternElement {
    /// Maps and validates the variable value to another
    /// - parameter input: The first parameter is the value is going to be transformed
    /// - parameter interpreter: Helps the mapper function to parse and interpret the contents
    /// - returns: The transformed value or nil, if the value was validated with a negative result
    public typealias VariableMapper<T, E> = (_ input: Any, _ interpreter: E) -> T?

    /// Unique identifier of the variable that is used when matching and returning them in the matcher.
    let name: String
    /// Options that modify the behaviour of the variable matching, and the output that the framework provides
    let options: VariableOptions
    /// The result of the evaluated variable will be running through this map function, transforming its value. By default the map tries to convert the matched value to the expected type, using the `as?` operator.
    let map: VariableMapper<T, E>

    /// Initialiser for all the properties
    /// - parameter name: `GenericVariable`s have a name (unique identifier), that is used when matching and returning them in the matcher.
    /// - parameter options: Options that modify the behaviour of the variable matching, and the output that the framework provides
    /// - parameter map: If provided, then the result of the evaluated variable will be running through this map function. By default the map tries to convert the matched value to the expected type, using the `as?` operator. Defaults to identical map, using the `as?` operator for value transformation
    public init(_ name: String,
                options: VariableOptions = [],
                map: @escaping VariableMapper<T, E> = { (value, _) in value as? T }) {
        self.name = name
        self.options = options
        self.map = map
    }

    /// `GenericVariables` always return anyMatch MatchResult, forwarding the shortest argument, provided during initialisation
    /// - parameter prefix: The input
    /// - returns: The result of the match operation. Always `anyMatch` with the shortest argument, provided during initialisation
    public func matches(prefix: String, options: PatternOptions = []) -> MatchResult<Any> {
        return .anyMatch(exhaustive: self.options.contains(.exhaustiveMatch))
    }

    /// A helper method to map the value of the current variable to another type
    /// - parameter map: The transformation function
    /// - parameter value: The value to be mapped
    /// - returns: A new variable instance using the value mapper block
    public func mapped<K>(_ map: @escaping (_ value: T) -> K?) -> GenericVariable<K, E> {
        return GenericVariable<K, E>(name, options: options) { value, interpreter in
            guard let value = self.map(value, interpreter) else { return nil }
            return map(value)
        }
    }

    /// The result of the evaluated variable will be ran through this map function, transforming its value. By default the map tries to convert the matched value to the expected type, using the `as?` operator.
    /// - parameter input: The first parameter is the value is going to be transformed
    /// - parameter interpreter: Helps the mapper function to parse and interpret the contents
    /// - returns: The transformed value or nil - if the value was validated with a negative result
    func performMap(input: Any, interpreter: Any) -> Any? {
        guard let interpreter = interpreter as? E else { return nil }
        return map(input, interpreter)
    }
}
