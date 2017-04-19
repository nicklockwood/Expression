//
//  PerformanceTests.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 24/05/2017.
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import XCTest
import Expression

let symbols: [Expression.Symbol: Expression.Symbol.Evaluator] = [
    .constant("a"): { _ in 5 },
    .constant("b"): { _ in 6 },
    .constant("c"): { _ in 7 },
    .constant("hello"): { _ in -5 },
    .constant("world"): { _ in -3 },
    .function("foo", arity: 0): { _ in .pi },
    .function("foo", arity: 2): { $0[0] - $0[1] },
    .function("bar", arity: 1): { $0[0] - 2 },
]

let shortExpressions = [
    "5",
    "a",
    "foo()",
    "hello",
    "67",
    "3.5",
    "pi"
]

let mediumExpressions = [
    "5 + 7",
    "a + b",
    "foo(5, 6)",
    "hello + world",
    "67 * 2",
    "3.5 / 6",
    "pi + 15"
]

let longExpressions = [
    "5 + min(a, b * 10)",
    "max(a + b, b + c)",
    "foo(5, 6 + bar(6))",
    "hello + world",
    "(67 * 2) + (68 * 3)",
    "3.5 / 6 + 1234 * 54",
    "pi * -56.4 + (5 + 4)"
]

let reallyLongExpression: String = {
    var parts = [String]()
    for i in 0 ..< 100 {
        parts.append("\(i)")
    }
    return "foo(" + parts.joined(separator: "+") + " + bar(5), a) + b"
}()

let repetitions = 200

class PerformanceTests: XCTestCase {

    // MARK: parsing

    func testParsingShortExpressions() {
        let expressions = shortExpressions
        self.measure {
            for _ in 0 ..< repetitions {
                for exp in expressions {
                    _ = Expression(exp)
                }
            }
        }
    }

    func testParsingMediumExpressions() {
        let expressions = mediumExpressions
        self.measure {
            for _ in 0 ..< repetitions {
                for exp in expressions {
                    _ = Expression(exp)
                }
            }
        }
    }

    func testParsingLongExpressions() {
        let expressions = longExpressions
        self.measure {
            for _ in 0 ..< repetitions {
                for exp in expressions {
                    _ = Expression(exp)
                }
            }
        }
    }

    func testParsingReallyLongExpressions() {
        let exp = reallyLongExpression
        self.measure {
            for _ in 0 ..< repetitions {
                _ = Expression(exp)
            }
        }
    }

    // MARK: evaluating

    func testEvaluatingShortExpressions() {
        let expressions = shortExpressions.map { Expression($0, symbols: symbols) }
        self.measure {
            for _ in 0 ..< repetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingMediumExpressions() {
        let expressions = mediumExpressions.map { Expression($0, symbols: symbols) }
        self.measure {
            for _ in 0 ..< repetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingLongExpressions() {
        let expressions = mediumExpressions.map { Expression($0, symbols: symbols) }
        self.measure {
            for _ in 0 ..< repetitions {
                for exp in expressions {
                    _ = try! exp.evaluate()
                }
            }
        }
    }

    func testEvaluatingReallyLongExpression() {
        let exp = Expression(reallyLongExpression, symbols: symbols)
        self.measure {
            for _ in 0 ..< repetitions {
                _ = try! exp.evaluate()
            }
        }
    }
}
