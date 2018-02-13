//
//  PerformanceTests.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 24/05/2017.
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

import Expression
import XCTest

class PerformanceTests: XCTestCase {

    private let parseRepetitions = 500
    private let evalRepetitions = 5000

    private struct HashableStruct: Hashable {
        let foo: Int
        var hashValue: Int {
            return foo.hashValue
        }

        static func == (lhs: HashableStruct, rhs: HashableStruct) -> Bool {
            return lhs.foo == rhs.foo
        }
    }

    // MARK: parsing

    func testParsingShortExpressions() {
        let expressions = shortExpressions
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression.parse(exp, usingCache: false)
                }
            }
        }
    }

    func testParsingMediumExpressions() {
        let expressions = mediumExpressions
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression.parse(exp, usingCache: false)
                }
            }
        }
    }

    func testParsingLongExpressions() {
        let expressions = longExpressions
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression.parse(exp, usingCache: false)
                }
            }
        }
    }

    func testParsingReallyLongExpressions() {
        let exp = reallyLongExpression
        measure {
            for _ in 0 ..< parseRepetitions {
                _ = Expression.parse(exp, usingCache: false)
            }
        }
    }

    func testParsingBooleanExpressions() {
        let expressions = booleanExpressions
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression.parse(exp, usingCache: false)
                }
            }
        }
    }

    // MARK: optimizing

    func testOptimizingShortExpressions() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, options: .pureSymbols, symbols: symbols)
                }
            }
        }
    }

    func testOptimizingShortExpressionsWithNewInitializer() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, impureSymbols: { _ in nil }, pureSymbols: { symbols[$0] })
                }
            }
        }
    }

    func testOptimizingShortAnyExpressions() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, options: .pureSymbols, symbols: anySymbols)
                }
            }
        }
    }

    func testOptimizingShortAnyExpressionsWithNewInitializer() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, impureSymbols: { _ in nil }, pureSymbols: { anySymbols[$0] })
                }
            }
        }
    }

    func testOptimizingMediumExpressions() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, options: .pureSymbols, symbols: symbols)
                }
            }
        }
    }

    func testOptimizingMediumExpressionsWithNewInitializer() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, impureSymbols: { _ in nil }, pureSymbols: { symbols[$0] })
                }
            }
        }
    }

    func testOptimizingMediumAnyExpressions() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, options: .pureSymbols, symbols: anySymbols)
                }
            }
        }
    }

    func testOptimizingMediumAnyExpressionsWithNewInitializer() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, impureSymbols: { _ in nil }, pureSymbols: { anySymbols[$0] })
                }
            }
        }
    }

    func testOptimizingLongExpressions() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, options: .pureSymbols, symbols: symbols)
                }
            }
        }
    }

    func testOptimizingLongExpressionsWithNewInitializer() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, impureSymbols: { _ in nil }, pureSymbols: { symbols[$0] })
                }
            }
        }
    }

    func testOptimizingLongAnyExpressions() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, options: .pureSymbols, symbols: anySymbols)
                }
            }
        }
    }

    func testOptimizingLongAnyExpressionsWithNewInitializer() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, impureSymbols: { _ in nil }, pureSymbols: { anySymbols[$0] })
                }
            }
        }
    }

    func testOptimizingReallyLongExpression() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure {
            for _ in 0 ..< parseRepetitions {
                _ = Expression(exp, options: .pureSymbols, symbols: symbols)
            }
        }
    }

    func testOptimizinReallyLongExpressionWithNewInitializer() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure {
            for _ in 0 ..< parseRepetitions {
                _ = Expression(exp, impureSymbols: { _ in nil }, pureSymbols: { symbols[$0] })
            }
        }
    }

    func testOptimizingReallyLongAnyExpression() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure {
            for _ in 0 ..< parseRepetitions {
                _ = AnyExpression(exp, options: .pureSymbols, symbols: anySymbols)
            }
        }
    }

    func testOptimizingReallyLongAnyExpressionWithNewInitializer() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure {
            for _ in 0 ..< parseRepetitions {
                _ = AnyExpression(exp, impureSymbols: { _ in nil }, pureSymbols: { anySymbols[$0] })
            }
        }
    }

    func testOptimizingBooleanExpressions() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, options: [.boolSymbols, .pureSymbols], symbols: symbols)
                }
            }
        }
    }

    func testOptimizingBooleanExpressionsWithNewInitializer() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = Expression(exp, impureSymbols: { _ in nil }, pureSymbols: { symbols[$0] })
                }
            }
        }
    }

    func testOptimizingBooleanAnyExpressions() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, options: [.boolSymbols, .pureSymbols], symbols: anySymbols)
                }
            }
        }
    }

    func testOptimizingBooleanAnyExpressionsWithNewInitializer() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure {
            for _ in 0 ..< parseRepetitions {
                for exp in expressions {
                    _ = AnyExpression(exp, impureSymbols: { _ in nil }, pureSymbols: { anySymbols[$0] })
                }
            }
        }
    }

    // MARK: evaluating

    func testEvaluatingShortExpressions() {
        let expressions = shortExpressions.map { Expression($0, options: .pureSymbols, symbols: symbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingShortAnyExpressions() {
        let expressions = shortExpressions.map { AnyExpression($0, options: .pureSymbols, symbols: anySymbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate() as Any
                }
            }
        }
    }

    func testEvaluatingMediumExpressions() {
        let expressions = mediumExpressions.map { Expression($0, options: .pureSymbols, symbols: symbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingMediumAnyExpressions() {
        let expressions = mediumExpressions.map { AnyExpression($0, options: .pureSymbols, symbols: anySymbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate() as Any
                }
            }
        }
    }

    func testEvaluatingLongExpressions() {
        let expressions = mediumExpressions.map { Expression($0, options: .pureSymbols, symbols: symbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingLongAnyExpressions() {
        let expressions = mediumExpressions.map { AnyExpression($0, options: .pureSymbols, symbols: anySymbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate() as Any
                }
            }
        }
    }

    func testEvaluatingReallyLongExpression() {
        let exp = Expression(reallyLongExpression, options: .pureSymbols, symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! exp.evaluate()
            }
        }
    }

    func testEvaluatingReallyLongAnyExpression() {
        let exp = AnyExpression(reallyLongExpression, options: .pureSymbols, symbols: anySymbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! exp.evaluate() as Any
            }
        }
    }

    func testEvaluatingBooleanExpressions() {
        let expressions = booleanExpressions.map { Expression($0, options: [.boolSymbols, .pureSymbols], symbols: symbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingBooleanAnyExpressions() {
        let expressions = booleanExpressions.map { AnyExpression($0, options: [.boolSymbols, .pureSymbols], symbols: anySymbols) }
        measure {
            for _ in 0 ..< evalRepetitions {
                for exp in expressions {
                    _ = try! exp.evaluate() as Any
                }
            }
        }
    }

    // MARK: == performance

    func testEquateDoubles() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in 5 },
            .variable("b"): { _ in 6 },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateBools() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in true },
            .variable("b"): { _ in false },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateStrings() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in "a" },
            .variable("b"): { _ in "b" },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateNSObjects() {
        let objectA = NSObject()
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in objectA },
            .variable("b"): { _ in NSObject() },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateArrays() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in ["hello"] },
            .variable("b"): { _ in ["goodbye"] },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateHashables() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in HashableStruct(foo: 5) },
            .variable("b"): { _ in HashableStruct(foo: 6) },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testCompareAgainstNil() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in NSNull() },
            .variable("b"): { _ in 5 },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure {
            for _ in 0 ..< evalRepetitions {
                _ = try! equalExpression.evaluate() as Any
                _ = try! unequalExpression.evaluate() as Any
            }
        }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }
}
