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

/// A tuple with the variable metadata and its value
/// - parameter metadata: Name, options, mapping information
/// - parameter value: The value of the variable
typealias VariableValue = (metadata: VariableProtocol, value: String)

/// A processor that can process a raw value with extra information, such as interpreter and context
internal protocol VariableProcessorProtocol {
    /// The method that can process the variable
    /// - parameter variable: The raw value to process
    /// - returns: The computed value of the variable
    func process(_ variable: VariableValue) -> Any?
}

/// A processor that can process a raw value with extra information, such as interpreter and context
internal class VariableProcessor<E: Interpreter> : VariableProcessorProtocol {
    /// An interpreter instance to use during the processing
    let interpreter: E
    /// The context to use during the processing
    let context: Context

    /// Initialiser of the processor
    /// - parameter interpreter: An interpreter instance to use during the processing
    /// - parameter context: The context to use during the processing
    init(interpreter: E, context: Context) {
        self.interpreter = interpreter
        self.context = context
    }

    /// Maps and evaluates variable content, based on its interpretation settings
    /// - parameter variable: The variable to process
    /// - returns: The result of the matching operation
    func process(_ variable: VariableValue) -> Any? {
        let value = variable.metadata.options.trimmed ? variable.value.trim() : variable.value
        if variable.metadata.options.interpreted {
            let variableInterpreter = interpreter.interpreterForEvaluatingVariables
            let output = variableInterpreter.evaluate(value, context: context)
            return variable.metadata.performMap(input: output, interpreter: variableInterpreter)
        }
        return variable.metadata.performMap(input: value, interpreter: interpreter)
    }
}

/// This class provides the main logic of the `Eval` framework, performing the pattern matching details
internal class Matcher {
    /// The elements in the pattern
    let elements: [PatternElement]
    /// A processor that is able to evaluate the variables with extra information, such as context and interpreter
    let processor: VariableProcessorProtocol
    /// Options for configuring the behaviour of the algorithm
    let options: PatternOptions

    /// Initialiser of the matcher
    /// - parameter elements: The elements in the pattern
    /// - parameter processor: A processor that is able to evaluate the variables with extra information, such as context and interpreter
    /// - parameter options: Options for configuring the behaviour of the algorithm
    init(elements: [PatternElement], processor: VariableProcessorProtocol, options: PatternOptions) {
        self.elements = elements
        self.processor = processor
        self.options = options
    }

    /// The active variable that can be appended during the execution, used by the helper methods
    private var currentlyActiveVariable: VariableValue?

    /// Tries to append the next input character to the currently active variables - if we have any
    /// - returns: Whether the append was successful
    private func tryToAppendCurrentVariable(remainder: inout String) -> Bool {
        if let variable = currentlyActiveVariable {
            appendNextCharacterToVariable(variable, remainder: &remainder)
        }
        return currentlyActiveVariable != nil
    }

    /// Appends the next character to the provided variables
    /// - parameter variable: The variable to append to
    /// - parameter remainder: The remainder of the evaluated input
    private func appendNextCharacterToVariable(_ variable: VariableValue, remainder: inout String) {
        if remainder.isEmpty {
            currentlyActiveVariable = (variable.metadata, variable.value)
        } else {
            if options.contains(.backwardMatch) {
                currentlyActiveVariable = (variable.metadata, String(describing: remainder.removeLast()) + variable.value)
            } else {
                currentlyActiveVariable = (variable.metadata, variable.value + String(describing: remainder.removeFirst()))
            }
        }
    }

    /// An element to initialise the variable with
    /// - parameter element: The variable element
    private func initialiseVariable(_ element: PatternElement) {
        if currentlyActiveVariable == nil, let variable = element as? VariableProtocol {
            currentlyActiveVariable = (variable, "")
        }
    }

    /// When the recognition of a variable arrives to the final stage, function finalises its value and appends the variables array
    /// - returns: Whether the registration was successful (the finalisation resulted in a valid value)
    private func registerAndValidateVariable(variables: inout [String: Any]) -> Bool {
        if let variable = currentlyActiveVariable {
            let result = processor.process(variable)
            variables[variable.metadata.name] = result
            return !variable.metadata.options.contains(.acceptsNilValue) && result != nil
        }
        return false
    }

    /// Increments the elementIndex value
    /// - parameter elementIndex: The index to be incremented
    private func nextElement(_ elementIndex: inout Int) {
        elementIndex += options.contains(.backwardMatch) ? -1 : 1
    }

    /// Checks whether the current index is the last one
    /// - parameter elementIndex: The index to be checked
    /// - returns: Whether the index is the last one of the elements array
    private func notFinished(_ elementIndex: Int) -> Bool {
        if options.contains(.backwardMatch) {
            return elementIndex >= elements.startIndex
        } else {
            return elementIndex < elements.endIndex
        }
    }

    /// Helper method to determine the first index of the collection, based on its options
    /// - returns: The first index of the collection
    private func initialIndex() -> Int {
        if options.contains(.backwardMatch) {
            return elements.index(before: elements.endIndex)
        } else {
            return elements.startIndex
        }
    }

    /// Removes and returns the next character from the input
    /// - parameter remainder: The remainder of the input
    /// - parameter length: The number of characters to be removed
    /// - returns: The last few characers from the input, defined by the `length` parameter
    private func drop(_ remainder: String, length: Int) -> String {
        if options.contains(.backwardMatch) {
            return String(remainder.dropLast(length))
        } else {
            return String(remainder.dropFirst(length))
        }
    }

    /// Removes whitespaces characters from the upcoming consecutive input characters
    /// - parameter remainder: The input to remove whitespaces from
    private func skipWhitespaces(_ remainder: inout String) {
        let whitespaces = CharacterSet.whitespacesAndNewlines
        repeat {
            if options.contains(.backwardMatch), let last = remainder.last?.unicodeScalars.first, whitespaces.contains(last) {
                _ = remainder.removeLast()
            } else if let first = remainder.first?.unicodeScalars.first, whitespaces.contains(first) {
                _ = remainder.removeFirst()
            } else {
                break
            }
        } while true
    }
    
    /// Removes whitespaces characters from the upcoming consecutive input characters, when the context allows to do so
    /// - parameter remainder: The input to remove whitespaces from
    /// - parameter index: The index of the current element
    private func skipWhitespacesIfNeeded(_ remainder: inout String, index: Int) {
        var shouldTrim = false
        if let variable = currentlyActiveVariable {
            shouldTrim = variable.metadata.options.trimmed
        } else if index < elements.endIndex && elements[index] is Keyword {
            shouldTrim = true
        }
        if shouldTrim && notFinished(index) {
            skipWhitespaces(&remainder)
        }
    }

    /// This match method provides the main logic of the `Eval` framework, performing the pattern matching, trying to identify, whether the input string is somehow related, or completely matches the pattern.
    /// - parameter string: The input
    /// - parameter from: The start of the range to analyse the result in
    /// - parameter renderer: If the result is an exactMatch, it uses this renderer block to compute the output based on the matched variables
    /// - parameter variables: The set of variables collected during the execution
    /// - returns: The result of the matching operation
    func match<T>(string: String, from start: Int = 0, renderer: @escaping (_ variables: [String: Any]) -> T?) -> MatchResult<T> {
        // swiftlint:disable:previous cyclomatic_complexity
        let trimmed = String(string[start...])
        var elementIndex = initialIndex()
        var remainder = trimmed
        var variables: [String: Any] = [:]

        repeat {
            let element = elements[elementIndex]
            let result = element.matches(prefix: remainder, options: options)

            switch result {
            case .noMatch:
                guard tryToAppendCurrentVariable(remainder: &remainder) else { return .noMatch }
            case .possibleMatch:
                return .possibleMatch
            case .anyMatch(let exhaustive):
                initialiseVariable(element)
                if exhaustive {
                    _ = tryToAppendCurrentVariable(remainder: &remainder)
                    if remainder.isEmpty {
                        guard registerAndValidateVariable(variables: &variables) else { return .possibleMatch }
                        nextElement(&elementIndex)
                    }
                } else {
                    nextElement(&elementIndex)
                }
            case let .exactMatch(length, _, embeddedVariables):
                if isEmbedded(element: element, in: String(string[start...]), at: trimmed.count - remainder.count) {
                    let isSuccess = tryToAppendCurrentVariable(remainder: &remainder)
                    if !isSuccess {
                        nextElement(&elementIndex)
                    }
                } else {
                    variables.merge(embeddedVariables) { (key, _) in key }
                    if currentlyActiveVariable != nil {
                        guard registerAndValidateVariable(variables: &variables) else { return .noMatch }
                        currentlyActiveVariable = nil
                    }
                    nextElement(&elementIndex)
                    remainder = drop(remainder, length: length)
                    skipWhitespacesIfNeeded(&remainder, index: elementIndex)
                }
            }
        } while notFinished(elementIndex)

        if let renderedOutput = renderer(variables) {
            return .exactMatch(length: string.count - start - remainder.count, output: renderedOutput, variables: variables)
        } else {
            return .noMatch
        }
    }

    /// Determines whether the current character is an `OpenKeyword`, so there might be another embedded match later
    /// - parameter element: The element to check whether it's an `OpenKeyword`
    /// - parameter in: The input
    /// - parameter at: The starting position to check from
    /// - returns: Whether the element conditions apply and the position is before the last one
    func isEmbedded(element: PatternElement, in string: String, at currentPosition: Int) -> Bool {
        if let closingTag = element as? Keyword, closingTag.type == .closingStatement, let closingPosition = positionOfClosingTag(in: string),
            currentPosition < closingPosition {
            return true
        }
        return false
    }

    /// Determines whether the current character is an `OpenKeyword` and fins the position of its appropriate `ClosingKeyword` pair
    /// - parameter in: The input
    /// - parameter from: The starting position of the checking range
    /// - returns: `nil` if the `CloseKeyword` pair cannot be found. The position otherwise
    func positionOfClosingTag(in string: String, from start: Int = 0) -> Int? {
        if let opening = elements.first(where: { ($0 as? Keyword)?.type == .openingStatement }) as? Keyword,
            let closing = elements.first(where: { ($0 as? Keyword)?.type == .closingStatement }) as? Keyword {
            var counter = 0
            var position = start
            repeat {
                var isCloseTagEarlier = false
                if let open = string.position(of: opening.name, from: position),
                    let close = string.position(of: closing.name, from: position),
                    close < open {
                    isCloseTagEarlier = true
                }

                if let open = string.position(of: opening.name, from: position), !isCloseTagEarlier {
                    counter += 1
                    position = open + opening.name.count
                } else if let close = string.position(of: closing.name, from: position) {
                    counter -= 1
                    if counter == 0 {
                        return close
                    }
                    position = close + closing.name.count
                } else {
                    break
                }
            } while true
        }
        return nil
    }
}
