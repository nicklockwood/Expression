# Change Log

## [0.4.0](https://github.com/nicklockwood/Expression/releases/tag/0.4.0) (2017-03-27)

- You can now get all symbols used by an expression via the `symbols` property
- Fixed crash with postfix operators followed by comma or closing paren

## [0.3](https://github.com/nicklockwood/Expression/releases/tag/0.3) (2017-01-04)

- Fixed crash when processing malformed expression
- Added support for Swift Package Manager and Linux
- Updated for latest Xcode version

## [0.2](https://github.com/nicklockwood/Expression/releases/tag/0.2) (2016-10-15)

- `Expression.init` no longer throws. The expression will still be compiled on init, but errors won't be thrown until first evaluation
- Added optional `constants` and `symbols` arguments to `Expression.init` for simpler setup of custom functions and operators
- Removed the `constants` param from the `evaluate()` function - this can now be provided in `Expression.init`
- Added automatic error reporting for custom functions called with the wrong arity
- Improved evaluation performance for built-in symbols

## [0.1](https://github.com/nicklockwood/Expression/releases/tag/0.1) (2016-10-01)

- First release
