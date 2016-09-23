[![Travis](https://img.shields.io/travis/nicklockwood/Expression.svg?maxAge=2592000)](https://travis-ci.org/nicklockwood/Expression)
[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
[![CocoaPods](https://img.shields.io/cocoapods/p/Expression.svg?maxAge=2592000)](https://cocoapods.org/pods/Expression)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/Expression.svg?maxAge=2592000)](http://cocoadocs.org/docsets/Expression/)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg?maxAge=2592000)](http://twitter.com/nicklockwood)


What is this?
----------------

Expression is a library for Mac and iOS for calculating numeric expressions at runtime.


Why would I want to do that?
-----------------------------

There are many situations where it is useful to be able to evaluate a simple expression at runtime. I've included a couple of example apps with the library:

* A scientific calculator
* A basic layout engine, similar to AutoLayout

but there are other possible applications, e.g.

* A spreadsheet app
* Configuration (e.g. using expressions in a config file to avoid data duplication)
* The basis for simple scripting language

(If you find any other uses, let me know and I'll add them)

Normally these kind of calculations would involve embedding a heavyweight interpreted language such as JavaScript or Lua into your app. Expression avoids that overhead, and is also more secure, as it reduces the risk of arbitrary code injection, or crashes due to infinite loops, etc.

Expression is lightweight, well-tested, and written entirely in Swift 3.


How do I install it?
---------------------

It's just a single class, so you can simply drag the `Expression.swift` file into your project to use it. There's also a framework for Mac and iOS if you prefer to make things complicated, or you can use Cocoapods or Carthage if you prefer.


How do I use it?
----------------

You create an `Expression` instance by passing a string containing your expression, and (optionally) an `Evaluator` function to implement custom behavior. You can then calculate the result by calling the `Expression.evaluate()` function.

The default evaluator implements standard math functions and operators, so a custom one is only needed if your app supports additional functions or variables:

    // Basic usage
    
    let expression = try! Expression("5 + 6")
    let result = try! expression.evaluate() // 11
    
    // Advanced usage
    
    do {
		let expression = try Expression("foo + bar(5)") { symbol, args in
			switch symbol {
				case .constant("foo"):
					return 5
				case .function("bar", arity: 1):
					return args[0] + 1
				default:
					return nil // pass to default evaluator
			}
		}
		let result = try expression.evaluate() // 11
	} catch {
		print("Error: \(error)")
	}
    	
Note that both the `Expression()` initializer and the `evaluate()` function can both throw an error. An error will be thrown during initialization if the expression is malformed, and during evaluation if it references an unknown symbol.

For a simple hard-coded expression like the first example, there is no possibility of an error being thrown, but if you are accepting user input as your expression you must always ensure that you catch and handle errors. The error messages produced by Expression are detailed and human-readable (but not localized, unfortunately).

Your custom `Evaluator` function can return either a `Double` or `nil` or it can throw an error. It is generally recommended that if you do not recognize a symbol, you shoud return nil so that it can be handled by the default evaluator.

In some case you may be certain that a symbol is incorrect,, however, and this is an opportunity to provide a more useful error message. In the example above, the evaluator matches the function `bar` with an arity of 1 (meaning that it takes one argument). This will only match calls to bar that take a single argument, and ignore calls with zero or multiple arguments.

Since `bar` is a custom function, we know that it should only take one argument, so it is probably more helpful to throw an error if it is called with the wrong number of arguments. That would look something like this:

	switch symbol {
		case .constant("foo"):
			return 5
		case .function("bar", let arity):
			guard arity == 1 else { throw Expression.Error.arityMismatch(symbol) }
			return args[0] + 1
		default:
			return nil // pass to default evaluator
	}

Note that you can check the arity of the function either using pattern matching (as we did above), or just by checking args.count. These will always match.

As a convenience, if you just need to include some custom constants, you can pass them as a dictionary to the `evaluate()` function:

    let expression = try! Expression("foo + bar")
    let result = try! expression.evaluate(["foo": 5, "bar": 6]) // 11
    
    
Symbols
--------------

Expressions are formed from symbols, defined by the `Expression.Symbol` enum type. The default evaluator defines several of these, but you are free to define your own in your custom evaluator function.

The Expression library supports the following symbol types:

    `.constant(String)`
    
This is an alphanumeric identifier representing a constant or variable in an expression. Identifiers can be any valid sequence of letters and numbers, beginning with a letter, underscore (_), dollar symbol ($), at sign (@) or pound sign (#).

Like Swift, Expression allows certain unicode chracters in identifier, such as emoji and scientific symbols. Unlike Swift, Expression's identifiers may also contain periods (.) as separators, which is useful for namespacing (as demonstrated in the Layout app).

	`.infix(String)`
	`.prefix(String)`
	`.postfix(String)`
	
These symbols represent operators. Currently operators must be a single character, but can be almost any symbol that wouldn't conflict with the possible identifier names. You can overload existing infix operators with a post/prefix variant, or vice-versa. Disambiguation depends on the white-space surrounding the operator (which is the same approach used by Swift), although where possible, Expression will attempt to disambiguate from context as well.

Any valid identifier may also be used as a postfix operator, by placing it after an operator or literal value. For example, you could define `m` and `cm` as postfix operators when handling distance logic, or `hours`, `minutes` and `seconds` operators for computing times.

Operator precedence follows standard BODMAS order, with multiplication/division given precedence over addition/subtraction.

     `.function(String, arity: Int)`
     
Functions can be defined as any valid identifier followed by a comma-delimited sequence of arguments in parentheses. Functions can be overloaded to support different argument counts, but it is up to you to handle argument validation in your evaluator function.
     
     
Default Evaluator
-------------------

The default evaluator implements a sort of "standard library" for Expressions. These consist of basic math functions and constants that arg egenrally useful, independent of a particular application.

If you use a custom evaluator function, you can override the default evaluator functions and operators by matching them and handling them in your own `switch` statement. You can fall back to the default evaluator's implementation by returning `nil` for unrecognized symbols.

If you do not want to invoke the standard library functions, throw an `Error` for unrecognized symbols instead of returning `nil`.

Here is current supported list of standard library symbols:

**constants**

	pi
	
**infix operators**

    + - / *
    
**prefix operators**

    -
    
**functions**

	sqrt(x)
    floor(x)
    ceil(x)
    round(x)
    cos(x)
    acos(x)
    sin(x)
    asin(x)
    tan(x)
    atan(x)
    abs(x)
    
	pow(x,y)
    max(x,y)
    min(x,y)
    atan2(x,y)
    mod(x,y)
    
    
Calculator example
--------------------

This is a simple gr
     

What's next?
--------------

* Support for more operator symbols
* More default evaluator functions
* Less boilerplate-y handling of arity errors
* Performance tuning, etc.

     
Release notes
----------------

Version 0.1

- First release
