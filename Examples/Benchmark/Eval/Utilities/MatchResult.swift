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

/// Whenever a match operation is performed, the result is going to be a `MatchResult` instance.
public enum MatchResult<T> {
    /// The input could not be matched
    case noMatch
    /// The input can match, if it were continued. (It's the prefix of the matching expression)
    case possibleMatch
    /// The input matches the expression. It provides information about the `length` of the matched input, the `output` after the evaluation, and the `variables` that were processed during the process.
    /// - parameter length: The length of the match in the input string
    /// - parameter output: The interpreted content
    /// - parameter variables: The key-value pairs of the found `Variable` instances along the way
    case exactMatch(length: Int, output: T, variables: [String: Any])
    /// In case the matching sequence only consists of one variable, the result is going to be anyMatch
    /// - parameter exhaustive: Whether the matching should be exaustive or just return the shortest matching result
    case anyMatch(exhaustive: Bool)

    /// Shorter syntax for pattern matching `MatchResult.exactMatch`
    /// - returns: Whether the case of the current instance is `exactMatch`
    func isMatch() -> Bool {
        if case .exactMatch(_, _, _) = self {
            return true
        }
        return false
    }

    /// Shorter syntax for pattern matching `MatchResult.anyMatch`
    /// - parameter exhaustive: If the result is `anyMatch`, this one filter the content by its exhaustive parameter - if provided. Uses `false` otherwise
    /// - returns: Whether the case of the current instance is `anyMatch`
    func isAnyMatch(exhaustive: Bool = false) -> Bool {
        if case .anyMatch(let parameter) = self {
            return exhaustive == parameter
        }
        return false
    }

    /// Shorter syntax for pattern matching `MatchResult.noMatch`
    /// - returns: Whether the case of the current instance is `noMatch`
    func isNoMatch() -> Bool {
        if case .noMatch = self {
            return true
        }
        return false
    }

    /// Shorter syntax for pattern matching `MatchResult.anypossibleMatch`
    /// - returns: Whether the case of the current instance is `possibleMatch`
    func isPossibleMatch() -> Bool {
        if case .possibleMatch = self {
            return true
        }
        return false
    }
}

/// `MatchResult` with Equatable objects are also Equatable
public extension MatchResult where T: Equatable {
    /// `MatchResult` with Equatable objects are also Equatable
    /// - parameter lhs: Left hand side
    /// - parameter rhs: Right hand side
    /// - returns: Whether the `MatchResult` have the same values, including the contents of their associated objects
    static func == (lhs: MatchResult<T>, rhs: MatchResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.noMatch, .noMatch), (.possibleMatch, .possibleMatch):
            return true
        case let (.anyMatch(lhsShortest), .anyMatch(rhsShortest)):
            return lhsShortest == rhsShortest
        case let (.exactMatch(lhsLength, lhsOutput, lhsVariables), .exactMatch(rhsLength, rhsOutput, rhsVariables)):
            return lhsLength == rhsLength && lhsOutput == rhsOutput && (lhsVariables as NSDictionary).isEqual(to: rhsVariables)
        default:
            return false
        }
    }
}
