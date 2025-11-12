# Changes to CSS Parser Algorithms

### 2.2.0 (June 1, 2023)

- Add `state` to `walk` methods.

This makes it possible pass down information from a parent structure to children.  
e.g. you can set `entry.state.isInCalcExpression = true` for `calc((10 + 5) / 2)` when walking the `FunctionNode` for `calc`.

### 2.1.1 (April 10, 2023)

- Updated `@csstools/css-tokenizer` to `2.1.1` (patch)

### 2.1.0 (March 25, 2023)

- Add `replaceComponentValues` utility function.
- Add `stringify` utility function.

### 2.0.1 (January 28, 2023)

- Improve `types` declaration in `package.json`

### 2.0.0 (January 19, 2023)

- Fix: Removes `UnclosedFunctionNode` and `UnclosedSimpleBlockNode`. (breaking)
- Change the `ParseError` interface, this is now a subclass of `Error` (breaking)
- Change `nameTokenValue` in `FunctionNode` to `getName` (breaking)
- Fix: Do not discard empty items in comma separated lists.

### 1.0.0 (November 14, 2022)

- Initial version
