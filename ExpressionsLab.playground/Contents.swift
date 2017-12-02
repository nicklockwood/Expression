//: Playground - noun: a place where people can play

import Cocoa
//import Expression

var text = "3 *-4"

let result = try Expression(text).evaluate()

print (result)

var variables: [Double] = [0, 0]
let expression = Expression("a = 5") { symbol, args in
    switch symbol {
    case .infix("="):
        print (args)
        variables[Int(args[0])] = args[1]
        return args[1]
    case .variable("a"):
        return 0
    case .variable("b"):
        return 1
    default:
        return nil
    }
}

try expression.evaluate()

Swift.print (variables)

