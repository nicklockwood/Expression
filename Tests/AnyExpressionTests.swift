//
//  ExpressionTests.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 18/04/2017.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
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

@testable import Expression
import XCTest

class AnyExpressionTests: XCTestCase {

    // MARK: Description

    func testDescriptionFormatting() {
        let expression = AnyExpression("a+b")
        XCTAssertEqual(expression.description, "a + b")
    }

    func testStringLiteralDescriptionNotMangled() {
        let expression = AnyExpression("foo('bar')")
        XCTAssertEqual(expression.description, "foo('bar')")
    }

    func testStringConstantDescriptionNotMangled() {
        let expression = AnyExpression("foo(bar)", constants: ["bar": "bar"])
        // TODO: would be nice if value could still be inlined, as with Expression
        XCTAssertEqual(expression.description, "foo(bar)")
    }

    // MARK: Arrays

    func testLookUpArrayConstant() {
        let expression = AnyExpression("a[b]", constants: [
            "a": ["hello", "world"],
            "b": 1,
        ])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(try expression.evaluate() as String, "world")
    }

    func testLookUpArrayWithString() {
        let expression = AnyExpression("a[b]", constants: [
            "a": ["hello", "world"],
            "b": "oops",
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("out of bounds"))
        }
    }

    func testCompareEqualArrays() {
        let expression = AnyExpression("a == b", constants: [
            "a": ["hello", "world"],
            "b": ["hello", "world"],
        ])
        XCTAssertTrue(try expression.evaluate())
    }

    func testCompareUnequalArrays() {
        let expression = AnyExpression("a == b", constants: [
            "a": ["hello", "world"],
            "b": ["world", "hello"],
        ])
        XCTAssertFalse(try expression.evaluate())
    }

    func testCompareStringAndArray() {
        let expression = AnyExpression("a == b", constants: [
            "a": ["world", "hello"],
            "b": "hello world",
        ])
        XCTAssertFalse(try expression.evaluate())
    }

    func testCustomArraySymbol() {
        let expression = AnyExpression("a[100000000]", symbols: [
            .array("a"): { args in args[0] }
        ])
        XCTAssertEqual(try expression.evaluate(), 100000000)
    }

    // MARK: Numeric types

    func testAddNumbers() {
        let expression = AnyExpression("4 + 5")
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    func testAddNumericConstants() {
        let expression = AnyExpression("a + b", constants: [
            "a": UInt64(4),
            "b": 5,
        ])
        XCTAssertEqual(try expression.evaluate(), 9)
    }

    func testPreserveNumericPrecision() {
        let expression = AnyExpression("true ? a : b", constants: [
            "a": UInt64.max,
            "b": Int64.min,
        ])
        XCTAssertEqual(try expression.evaluate(), UInt64.max)
    }

    func testAddVeryLargeNumericConstants() {
        let expression = AnyExpression("a + b", constants: [
            "a": Int64.max,
            "b": Int64.max,
        ])
        XCTAssertEqual(try expression.evaluate(), Double(Int64.max) + Double(Int64.max))
    }

    func testNaN() {
        let expression = AnyExpression("NaN + 5", constants: ["NaN": Double.nan])
        XCTAssertEqual((try expression.evaluate() as Double).isNaN, true)
    }

    func testEvilEdgeCase() {
        let evilValue = (-Double.nan) // exactly matches mask
        let expression = AnyExpression("evil + 5", constants: ["evil": evilValue])
        XCTAssertEqual((try expression.evaluate() as Double).bitPattern, evilValue.bitPattern)
    }

    func testEvilEdgeCase2() {
        let evilValue = Double(bitPattern: (-Double.nan).bitPattern + 2) // outside range of stored variables
        let expression = AnyExpression("evil + 5", constants: ["evil": evilValue])
        XCTAssertEqual((try expression.evaluate() as Double).bitPattern, evilValue.bitPattern)
    }

    func testFloatNaN() {
        let expression = AnyExpression("NaN + 5", constants: ["NaN": Float.nan])
        XCTAssertEqual((try expression.evaluate() as Double).isNaN, true)
    }

    func testInfinity() {
        let expression = AnyExpression("1/0")
        XCTAssertEqual((try expression.evaluate() as Double).isInfinite, true)
    }

    func testCGFloatTreatedAsDouble() throws {
        let expression = AnyExpression("foo + 5", constants: ["foo": CGFloat(5)])
        let result: Any = try expression.evaluate()
        XCTAssertEqual("\(type(of: result))", "Double")
        XCTAssertEqual(result as? Double, 10)
    }

    func testFontWeightTypePreserved() throws {
        let expression = AnyExpression("foo", constants: ["foo": NSFont.Weight(5)])
        let result: Any = try expression.evaluate()
        XCTAssertEqual("\(type(of: result))", "Weight")
    }

    // MARK: String concatenation

    func testAddStringConstants() {
        let expression = AnyExpression("a + b", constants: [
            "a": "foo",
            "b": "bar",
        ])
        XCTAssertEqual(try expression.evaluate(), "foobar")
    }

    func testAddNumericConstantsWithString() {
        let expression = AnyExpression("a + b == 9 ? c : ''", constants: [
            "a": 4,
            "b": 5,
            "c": "foo",
        ])
        XCTAssertEqual(try expression.evaluate(), "foo")
    }

    func testAddStringLiterals() {
        let expression = AnyExpression("'foo' + 'bar'")
        XCTAssertEqual(try expression.evaluate(), "foobar")
    }

    func testAddNumberToString() {
        let expression = AnyExpression("5 + 'foo'")
        XCTAssertEqual(try expression.evaluate(), "5foo")
    }

    func testAddStringToInt() {
        let expression = AnyExpression("'foo' + 5")
        XCTAssertEqual(try expression.evaluate(), "foo5")
    }

    func testAddStringToBigInt() {
        let expression = AnyExpression("'foo' + bar", constants: ["bar": UInt64.max])
        XCTAssertEqual(try expression.evaluate(), "foo\(UInt64.max)")
    }

    func testAddStringToDouble() {
        let expression = AnyExpression("'foo' + 5.1")
        XCTAssertEqual(try expression.evaluate(), "foo5.1")
    }

    func testAddStringToFalse() {
        let expression = AnyExpression("'foo' + false")
        XCTAssertEqual(try expression.evaluate(), "foofalse")
    }

    func testAddStringToTrue() {
        let expression = AnyExpression("'foo' + true")
        XCTAssertEqual(try expression.evaluate(), "footrue")
    }

    func testAddStringVariables() {
        let expression = AnyExpression("a + b", symbols: [
            .variable("a"): { _ in "foo" },
            .variable("b"): { _ in "bar" },
        ])
        XCTAssertEqual(expression.symbols, [.variable("a"), .variable("b"), .infix("+")])
        XCTAssertEqual(try expression.evaluate(), "foobar")
    }

    func testAddStringVariables2() {
        let expression = AnyExpression("a + b") { symbol, _ in
            switch symbol {
            case .variable("a"):
                return "foo"
            case .variable("b"):
                return "bar"
            default:
                return nil
            }
        }
        XCTAssertEqual(expression.symbols, [.variable("a"), .variable("b"), .infix("+")])
        XCTAssertEqual(try expression.evaluate(), "foobar")
    }

    func testAddMixedConstantsAndVariables() {
        let expression = AnyExpression(
            "a + b + c",
            constants: [
                "a": "foo",
                "b": "bar",
            ],
            symbols: [
                .variable("c"): { _ in "baz" },
            ]
        )
        XCTAssertEqual(expression.symbols, [.variable("c"), .infix("+")])
        XCTAssertEqual(try expression.evaluate(), "foobarbaz")
    }

    // MARK: Boolean logic

    func testMixedConstantsAndVariables() {
        let expression = AnyExpression(
            "foo ? #F00 : #00F",
            constants: [
                "#F00": "red",
                "#00F": "blue",
            ],
            symbols: [
                .variable("foo"): { _ in false },
            ]
        )
        XCTAssertEqual(expression.symbols, [.variable("foo"), .infix("?:")])
        XCTAssertEqual(try expression.evaluate(), "blue")
    }

    func testEquateStrings() {
        let constants: [String: Any] = [
            "a": "foo",
            "b": "bar",
            "c": "bar",
        ]
        let expression1 = AnyExpression("a == b", constants: constants)
        XCTAssertFalse(try expression1.evaluate())
        let expression2 = AnyExpression("a != b", constants: constants)
        XCTAssertTrue(try expression2.evaluate())
        let expression3 = AnyExpression("b == c", constants: constants)
        XCTAssertTrue(try expression3.evaluate())
        let expression4 = AnyExpression("b != c", constants: constants)
        XCTAssertFalse(try expression4.evaluate())
    }

    func testEquateObjects() {
        let object1 = NSObject()
        let object2 = NSObject()
        let constants: [String: Any] = [
            "a": object1,
            "b": object2,
            "c": object2,
        ]
        let expression1 = AnyExpression("a == b", constants: constants)
        XCTAssertFalse(try expression1.evaluate())
        let expression2 = AnyExpression("a != b", constants: constants)
        XCTAssertTrue(try expression2.evaluate())
        let expression3 = AnyExpression("b == c", constants: constants)
        XCTAssertTrue(try expression3.evaluate())
    }

    func testGreaterThanWithLargeIntegers() {
        let expression = AnyExpression("a > b", constants: [
            "a": Int64.max,
            "b": Int64.max - 1000,
        ])
        XCTAssertTrue(try expression.evaluate())
    }

    func testLessThanEqualWithLargeIntegers() {
        let expression = AnyExpression("a <= b", constants: [
            "a": Int64.max,
            "b": Int64.max - 1000,
        ])
        XCTAssertFalse(try expression.evaluate())
    }

    func testAndOperatorReturnsBool() {
        let expression = AnyExpression("a && b", constants: [
            "a": true,
            "b": true,
        ])
        XCTAssertTrue(try expression.evaluate())
    }

    func testOrOperatorReturnsBool() {
        let expression = AnyExpression("a || b", constants: [
            "a": false,
            "b": false,
        ])
        XCTAssertFalse(try expression.evaluate())
    }

    func testNotNaNEqualsNan() {
        let expression = AnyExpression("NaN == NaN", constants: [
            "NaN": Double.nan,
        ])
        XCTAssertFalse(try expression.evaluate())
    }

    func testNaNNotEqualToNan() {
        let expression = AnyExpression("NaN != NaN", constants: [
            "NaN": Double.nan,
        ])
        XCTAssertTrue(try expression.evaluate())
    }

    func testNotFloatNaNEqualsNan() {
        let expression = AnyExpression("NaN == NaN", constants: [
            "NaN": Float.nan,
        ])
        XCTAssertFalse(try expression.evaluate())
    }

    // MARK: Optionals

    func testNilString() {
        let null: String? = nil
        let expression = AnyExpression("foo + 'bar'", constants: ["foo": null as Any])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testNilString2() {
        let null: String? = nil
        let expression1 = AnyExpression("foo == nil ? 'bar' : foo", constants: ["foo": null as Any])
        XCTAssertEqual(try expression1.evaluate(), "bar")
        let expression2 = AnyExpression("foo == nil ? 'bar' : foo", constants: ["foo": "foo"])
        XCTAssertEqual(try expression2.evaluate(), "foo")
    }

    func testIOUNilString() {
        let null: String! = nil
        let expression = AnyExpression("foo + 'bar'", constants: ["foo": null as Any])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testOptionalOptionalNilString() {
        let null: Optional<Optional<String>> = nil
        let expression = AnyExpression("foo + 'bar'", constants: ["foo": null as Any])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testOptionalOptionalNonnilString() {
        let foo: Optional<Optional<String>> = "foo"
        let expression = AnyExpression("foo + 'bar'", constants: ["foo": foo as Any])
        XCTAssertEqual(try expression.evaluate(), "foobar")
    }

    func testNullCoalescing() {
        let null: String? = nil
        let expression = AnyExpression("foo ?? 'bar'", constants: ["foo": null as Any])
        XCTAssertEqual(try expression.evaluate(), "bar")
    }

    func testNullCoalescing2() {
        let foo: String? = "foo"
        let expression = AnyExpression("foo ?? 'bar'", constants: ["foo": foo as Any])
        XCTAssertEqual(try expression.evaluate(), "foo")
    }

    func testIUONullCoalescing() {
        let null: String! = nil
        let expression = AnyExpression("foo ?? 'bar'", constants: ["foo": null as Any])
        XCTAssertEqual(try expression.evaluate(), "bar")
    }

    func testIUONullCoalescing2() {
        let foo: String! = "foo"
        let expression = AnyExpression("foo ?? 'bar'", constants: ["foo": foo as Any])
        XCTAssertEqual(try expression.evaluate(), "foo")
    }

    func testNSNullCoalescing() {
        let expression = AnyExpression("foo ?? 'bar'", constants: ["foo": NSNull()])
        XCTAssertEqual(try expression.evaluate(), "bar")
    }

    func testNonNullCoalescing() {
        let expression = AnyExpression("foo ?? 'bar'", constants: ["foo": "foo"])
        XCTAssertEqual(try expression.evaluate(), "foo")
    }

    func testNullEqualsString() {
        let null: String? = nil
        let expression = AnyExpression("foo == 'bar'", constants: ["foo": null as Any])
        XCTAssertFalse(try expression.evaluate())
    }

    func testOptionalStringEqualsString() {
        let null: String? = "bar"
        let expression = AnyExpression("foo == 'bar'", constants: ["foo": null as Any])
        XCTAssertTrue(try expression.evaluate())
    }

    func testNullEqualsDouble() {
        let null: Double? = nil
        let expression = AnyExpression("foo == 5.5", constants: ["foo": null as Any])
        XCTAssertFalse(try expression.evaluate())
    }

    func testOptionalDoubleEqualsDouble() {
        let null: Double? = 5.5
        let expression = AnyExpression("foo == 5.5", constants: ["foo": null as Any])
        XCTAssertTrue(try expression.evaluate())
    }

    // MARK: Errors

    func testUnknownOperator() {
        let expression = AnyExpression("'foo' %% 'bar'")
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("Undefined infix operator %%"))
        }
    }

    func testBinaryTernary() {
        let expression = AnyExpression("'foo' ?: 'bar'")
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("Undefined infix operator ?:"))
        }
    }

    func testTernaryWithNonBooleanArgument() {
        let expression = AnyExpression("'foo' ? 1 : 2")
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("arguments of type (String, Double, Double)"))
        }
    }

    func testAddDates() {
        let expression = AnyExpression("a + b", constants: [
            "a": Date(),
            "b": Date(),
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("arguments of type (Date, Date)"))
        }
    }

    func testCompareObjects() {
        let expression = AnyExpression("a > b", constants: [
            "a": NSObject(),
            "b": NSObject(),
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("arguments of type (NSObject, NSObject)"))
        }
    }

    func testAddStringAndNil() {
        let expression = AnyExpression("a + b", constants: [
            "a": "foo",
            "b": nil as Any? as Any,
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testAddStringAndNSNull() {
        let expression = AnyExpression("a + b", constants: [
            "a": "foo",
            "b": NSNull(),
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testAddIntAndNil() {
        let expression = AnyExpression("a + b", constants: [
            "a": 5,
            "b": nil as Any? as Any,
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testMultiplyIntAndNil() {
        let expression = AnyExpression("a * b", constants: [
            "a": 5,
            "b": nil as Any? as Any,
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testTypeMismatch() {
        let expression = AnyExpression("5 / 'foo'")
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("arguments of type (Double, String)"))
        }
    }

    func testCastStringAsDouble() {
        let expression = AnyExpression("'foo' + 'bar'")
        XCTAssertThrowsError(try expression.evaluate() as Double) { error in
            XCTAssert("\(error)".contains("Return type mismatch"))
        }
    }

    func testCastDoubleAsDate() {
        let expression = AnyExpression("5.6")
        XCTAssertThrowsError(try expression.evaluate() as NSDate) { error in
            XCTAssert("\(error)".contains("Return type mismatch"))
        }
    }

    func testCastNilAsDouble() {
        let expression = AnyExpression("nil")
        XCTAssertThrowsError(try expression.evaluate() as Double) { error in
            XCTAssert("\(error)".contains("Unexpected nil"))
        }
    }

    func testCastNSNullAsDouble() {
        let expression = AnyExpression("null", constants: ["null": NSNull()])
        XCTAssertThrowsError(try expression.evaluate() as Double) { error in
            XCTAssert("\(error)".contains("Unexpected nil"))
        }
    }

    func testDisableNullCoalescing() {
        let expression = AnyExpression("nil ?? 'foo'", symbols: [
            .infix("??"): { _ in throw AnyExpression.Error.message("Disabled") }
        ])
        XCTAssertThrowsError(try expression.evaluate() as Any) { error in
            XCTAssert("\(error)".contains("Disabled"))
        }
    }

    // MARK: Return type casting

    func testCastBoolResultAsDouble() {
        let expression = AnyExpression("5 > 4")
        XCTAssertEqual(try expression.evaluate(), 1.0)
    }

    func testCastDoubleResultAsInt() {
        let expression = AnyExpression("57.5")
        XCTAssertEqual(try expression.evaluate(), 57)
    }

    func testCastDoubleResultAsBool() {
        let expression = AnyExpression("0.6")
        XCTAssertEqual(try expression.evaluate(), true)
    }

    func testCastDoubleResultAsBool2() {
        let expression = AnyExpression("0")
        XCTAssertEqual(try expression.evaluate(), false)
    }

    func testCastDoubleAsString() {
        let expression = AnyExpression("5.6")
        XCTAssertEqual(try expression.evaluate(), "5.6")
    }

    func testCastDoubleResultAsOptionalDouble() {
        let expression = AnyExpression("5 + 4")
        XCTAssertEqual(try expression.evaluate() as Double?, 9)
    }

    func testCastNilResultAsOptionalDouble() {
        let expression = AnyExpression("nil")
        XCTAssertEqual(try expression.evaluate() as Double?, nil)
    }

    func testCastNSNullResultAsOptionalDouble() {
        let expression = AnyExpression("null", constants: ["null": NSNull()])
        XCTAssertEqual(try expression.evaluate() as Double?, nil)
    }

    func testCastNilResultAsAny() {
        let expression = AnyExpression("nil")
        XCTAssertEqual("\(try expression.evaluate() as Any)", "nil")
    }

    func testCastNilResultAsOptionalAny() {
        let expression = AnyExpression("nil")
        XCTAssertNil(try expression.evaluate() as Any?)
    }

    func testCastNSNullResultAsAny() {
        let expression = AnyExpression("null", constants: ["null": NSNull()])
        // TODO: should this be treated as nil instead?
        XCTAssertEqual("\(try expression.evaluate() as Any)", "\(NSNull())")
    }

    func testCastBoolResultAsOptionalBool() {
        let expression = AnyExpression("5 > 4")
        XCTAssertEqual(try expression.evaluate() as Bool?, true)
    }

    func testCastBoolResultAsOptionalDouble() {
        let expression = AnyExpression("5 > 4")
        XCTAssertEqual(try expression.evaluate() as Double?, 1)
    }

    // MARK: Optimization

    func testStringLiteralsInlined() {
        let expression = AnyExpression("foo('bar', 'baz')")
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 2)])
    }

    func testNumericConstantsInlined() {
        let expression = AnyExpression("foo(bar)", constants: ["bar": 5])
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 1)])
    }

    func testStringConstantsInlined() {
        let expression = AnyExpression("foo(bar)", constants: ["bar": "bar"])
        XCTAssertEqual(expression.symbols, [.function("foo", arity: 1)])
    }

    func testArrayConstantsInlined() {
        let expression = AnyExpression("foo[bar]", constants: ["foo": ["baz"], "bar": 0])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(try expression.evaluate(), "baz")
    }

    func testNullCoalescingOperatorInlined() {
        let expression = AnyExpression("maybe ?? 'foo'", constants: ["maybe": nil as Any? as Any])
        XCTAssertEqual(expression.symbols, [])
        XCTAssertEqual(try expression.evaluate(), "foo")
    }

    func testTimesOperatorInlinedForDoubles() {
        let expression = AnyExpression("5 * foo", constants: ["foo": 5])
        XCTAssertEqual(try expression.evaluate(), 25)
        // Note: symbol optimization is deferred, so symbols will
        // only be empty after the first evaluation
        XCTAssertEqual(expression.symbols, [])
    }

    func testPlusOperatorInlinedForDoubles() {
        let expression = AnyExpression("5 + foo", constants: ["foo": 5])
        XCTAssertEqual(try expression.evaluate(), 10)
        // Note: symbol optimization is deferred, so symbols will
        // only be empty after the first evaluation
        XCTAssertEqual(expression.symbols, [])
    }

    func testPlusOperatorNotInlinedForStrings() {
        let expression = AnyExpression("5 + foo", constants: ["foo": "bar"])
        XCTAssertEqual(try expression.evaluate(), "5bar")
        // Note: can't optimize concat operator because it needs to store result
        XCTAssertEqual(expression.symbols, [.infix("+")])
    }

    func testBooleanAndOperatorNotInlined() {
        let expression = AnyExpression("true && false")
        XCTAssertFalse(try expression.evaluate())
        // Note: can't currently optimize bool symbols because they need to store result
        XCTAssertEqual(expression.symbols, [.infix("&&")])
    }

    func testPureFunctionResultNotMangledByInlining() {
        let expression = AnyExpression("foo('bar')", options: .pureSymbols, symbols: [
            .function("foo", arity: 1): { args in "foo\(args[0])" }
        ])
        XCTAssertEqual(try expression.evaluate(), "foobar")
        XCTAssertEqual(try expression.evaluate(), "foobar")
    }
}
