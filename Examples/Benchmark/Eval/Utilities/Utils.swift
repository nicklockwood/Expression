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

/// Syntactic sugar for `MatchElement` instances to feel like concatenation, whenever the input requires an array of elements.
/// - parameter left: Left hand side
/// - parameter right: Right hand side
/// - returns: An array with two elements (left and right in this order)
public func + (left: PatternElement, right: PatternElement) -> [PatternElement] {
    return [left, right]
}

/// Syntactic sugar for appended arrays
/// - parameter array: The array to append
/// - parameter element: The appended element
/// - returns: A new array by appending `array` with `element`
internal func + <A>(array: [A], element: A) -> [A] {
    return array + [element]
}

/// Syntactic sugar for appending mutable arrays
/// - parameter array: The array to append
/// - parameter element: The appended element
internal func += <A> (array: inout [A], element: A) {
    array = array + element //swiftlint:disable:this shorthand_operator
}

/// Helpers on `String` to provide `Int` based subscription features and easier usage
extension String {
    /// Syntactic sugar for Int based string subsription
    /// - parameter offset: The position of the desired character
    /// - returns: The `Character` at the given position
    subscript (offset: Int) -> Character {
        return self[index(startIndex, offsetBy: offset)]
    }

    /// Syntactic sugar for Int range based string subsription (1...3)
    /// - parameter range: The range of the desired substring
    /// - returns: The `Substring` at the given range
    subscript (range: CountableRange<Int>) -> Substring {
        return self[index(startIndex, offsetBy: range.startIndex) ..< index(startIndex, offsetBy: range.endIndex)]
    }

    /// Syntactic sugar for Int range based string subsription (..<4)
    /// - parameter range: The range of the desired substring
    /// - returns: The `Substring` at the given range
    subscript (range: PartialRangeUpTo<Int>) -> Substring {
        return self[..<index(startIndex, offsetBy: range.upperBound)]
    }

    /// Syntactic sugar for Int range based string subsription (1...)
    /// - parameter range: The range of the desired substring
    /// - returns: The `Substring` at the given range
    subscript (range: CountablePartialRangeFrom<Int>) -> Substring {
        return self[index(startIndex, offsetBy: range.lowerBound)...]
    }

    /// Shorter syntax for trimming
    /// - returns: The `String` without the prefix and postfix whitespace characters
    func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Helper to find the next Int based index for a substring, from a given position
    /// - parameter target: The String to search for
    /// - parameter from: The location where the range starts. The ending location if the end of the string
    /// - returns: The position of the string - if found. `nil` otherwise
    func position(of target: String, from: Int = 0) -> Int? {
        return range(of: target, options: [], range: Range(uncheckedBounds: (index(startIndex, offsetBy: from), endIndex)))?.lowerBound.encodedOffset
    }
}
