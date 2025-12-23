# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2025-03-18

### Added

- Support `3.5` as a version option.
- Many, many compatibility fixes for the parser translation layer.
- Handle escapes in named capture names.
- The `freeze` option is added to the various `Prism::` APIs to deeply freeze the AST.
- Properly support `it` for the parser and ruby_parser translation layers.
- Track the `then` keyword on `rescue` nodes.
- Add a `multiple_statements?` flag to parentheses nodes to support desired `defined?` behavior.

### Changed

- The strings used in the AST are now frozen.
- Fixed handling escaped characters after control sequences in character literals.
- Fix reading off the end of an unterminated global variable.
- Raise a syntax error for defining `[]=` with endless method syntax.
- Increase value of `PRISM_DEPTH_MAXIMUM` to `10000`.
- Freeze `Prism::VERSION`.
- Fix up rescue modifier precedence.

## [1.3.0] - 2024-12-21

### Added

- Introduce `Prism::StringQuery`.
- Introduce `Prism::Relocation`.
- Track `do` keyword for `WhileNode` and `UntilNode`.
- Change the way the gem is built to rely on `mkmf` instead of `make`.
- Lots more documentation on node fields.

### Changed

- Properly add an error for `def @foo; end`.
- Properly add an error for `foo(**, *)`.
- Fix up regression in string parsing in `RubyParser` translation.
- Reject invalid dot method call after match expression.
- Reject invalid operator after match expression.
- Fix up %-literals delimited by newlines.
- Properly add an error for `-> { _1; -> { _1 } }`.
- Reject blocks and keywords in index writes.

## [1.2.0] - 2024-10-10

### Added

- Introduce `Prism::CodeUnitsCache`.

### Changed

- Properly handle lexing global variables that begin with `$-`.
- Properly reject invalid multi writes within parentheses.
- Fix unary `*` binding power.
- Set `contains_keywords` flag for implicit `gets` calls when `-p` is used.
- Properly reject invalid non-associative operator patterns.
- Do not warn about unused variables declared on negative lines.

## [1.1.0] - 2024-10-02

### Added

- Explicitly type each child node field in the Ruby API.
- Add the `main_script` option to the parse APIs, which controls whether or not shebangs are considered.
- Add the `partial_script` options to the parse APIs, which controls whether or not jumps that would otherwise be considered invalid are allowed. This is useful for parsing things like ERB sources, where you know it will be evaluated in a different context. Note that this functionality is replacing the previous idiom of passing in a list of scopes to indicate an `eval` context, because that behavior has changed upstream in `ruby/ruby`.
- Add `ArgumentsNode#contains_multiple_splats?`.
- Add `ArgumentsNode#contains_forwarding?`.
- Accept all valid Ruby versions for the `version` option on parse APIs.
- Accept version shorthands like `"3.3"` and `"3.4"` for the `version` option on parse APIs.
- Support a max depth to protect against malicious payloads without hitting the stack limit.

### Changed

- Fix some token incompatibilities in the `parser` translation.
- Fix up parsing tempfiles on Windows.
- Fix up handling UTF-8 characters in file paths on Windows.
- Do not warn for a `\r` at the end of a shebang on Windows.
- Properly handle erroring for parsing a directory on Windows.
- When a numbered reference is out of range, warn instead of raise.
- Allow returns in default parameter values.
- Reject many more invalid syntax patterns.

## [1.0.0] - 2024-08-28

### Added

- Add `Node#breadth_first_search`.
- Add `Node#node_id`.
- Add `ArgumentsNode#contains_splat?`.
- Passing the special value `false` for the `encoding` option tells Prism to ignore magic encoding comments.
- Expose flags on every node type (allows checking static literal and newline).
- Implement mismatched indentation warning.
- Add C API for receiving a callback when parsing shebangs with additional flags.

### Changed

- **BREAKING**: Some fields are renamed that had illogical names. The previous names all now emit deprecation warnings.
  - `CaseMatchNode#consequent` was renamed to `CaseMatchNode#else_clause`
  - `CaseNode#consequent` was renamed to `CaseNode#else_clause`
  - `IfNode#consequent` was renamed to `IfNode#subsequent`
  - `RescueNode#consequent` was renamed to `RescueNode#subsequent`
  - `UnlessNode#consequent` was renamed to `UnlessNode#else_clause`
- Block exits are now allowed in loop predicates (e.g., `while _ && break do end`).
- Multi-writes are now disallowed when not at the statement level.
- Ensure that range operators are non-associative.
- (JavaScript) Correctly deserialize encoded strings.
- Properly support parsing regular expressions in extended mode.
- Use gmake on FreeBSD.
- Parsing streams now handles NUL bytes in the middle of the stream.
- Properly detect invalid returns.

## [0.30.0] - 2024-06-07

### Added

- More correctly raise mixed encoding errors.
- Implement ambiguous binary operator warning.
- Fix up regexp escapes with control and meta characters.
- Fix up support for the `it` implicit local variable.
- Heredoc identifiers now properly disallow CLRF.
- Errors added for void value expressions in begin clauses.
- Many updates to more closely match the `parser` gem in parser translation.
- Many errors added for invalid regular expressions.

### Changed

- Handle parser translation missing the `parser` gem.
- Handle ruby_parser translation missing the `ruby_parser` gem.
- Various error messages have been updated to more closely match CRuby.
- `RationalNode` now has a `numerator` and `denominator` field instead of a `numeric` field. For the Ruby API we provide a `RationalNode#numeric` method for backwards-compatibility.

## [0.29.0] - 2024-05-10

### Added

- Added `Prism::CallNode#full_message_loc`, which gives the location including the `=` if there is one.
- A warning for when `# shareable_constant_value` is not used on its own line.
- An error for invalid implicit local variable writes.
- Implicit hash patterns in array patterns are disallowed.
- We now validate that Unicode escape sequences are not surrogates.

### Changed

- All fields named `operator` have been renamed to `binary_operator` for `*OperatorWriteNode` nodes. This is to make it easier to provide C++ support. In the Ruby API, the old fields are aliased to the new fields with a deprecation warning.
- Many updated error messages to more closely match CRuby.
- We ensure keyword parameters do not end in `!` or `?`.
- Fixed some escaping in string literals with control sequences and hex escapes.
- Fix a bug with RBS types when used outside the `ruby/prism` codebase.

## [0.28.0] - 2024-05-03

### Added

- Nested hashes will now warn for duplicated keys, as in: `{ foo: 1, **{ foo: 2 } }`.
- `Prism::ReturnNode` now has a flag on it to indicate if it is redundant.
- `Prism::Location#slice_lines` and `Prism::Node#slice_lines` are now provided to slice the source code of a node including the content before the node on the same line that it starts on and the content after the node on the same line that it ends on.
- Symbols with invalid byte sequences now give errors.
- You can now pass `"3.3.1"` to the `version:` parameter on all `Prism.*` APIs.
- `Prism::Source#lines`, `Prism::Location#source_lines`, `Prism::Node#source_lines`, and `Prism::Node#script_lines` are now provided, which will all return the source code of the source as an array of strings.
- `Prism::ASCIISource` is now provided, which is a subclass of `Prism::Source` but specialized to increase performance when the source is entirely ASCII.
- Prism now provides errors when parsing Ruby 3.4+ syntax for index expressions with keywords or blocks.
- Prism now provides an error when `**nil` is used after other keyword parameters.
- Prism now provides errors when safe navigation is used in call target expressions, e.g., `foo&.bar, = 1`.
- `Prism::Node#tunnel` is now provided, which returns an array of nodes starting at the current node that contain a given line and column.

### Changed

- All translation layers now assume an eval context, which means they will not return errors for invalid jumps like `yield`.
- `Prism::Node#inspect` now uses a queue instead of recursion to avoid stack overflows.
- Prism now more closely mirrors CRuby interpolation semantics, which means you could potentially have a static literal string that directly interpolates another static literal string.
- The shipped RBI sorbet types no longer use generics.
- `Prism::ConstantPathNode#child` and `Prism::ConstantTargetNode#child` are now deprecated, replaced by two new fields on these nodes: `name` and `name_loc`.

## [0.27.0] - 2024-04-23

### Added

- Implemented `===` for each of the nodes, which will check if equality but ignore the specific ranges of locations.

### Changed

- Fix translation of `ItParametersNode` for parser translation.
- Fix translation of `dstr` for ruby_parser translation.
- Do not allow omitted hash values whose keys end with `!` or `?`.
- Split up `Prism::ParseResult` into `Prism::Result` with subclasses `Prism::ParseResult`, `Prism::LexResult`, `Prism::ParseLexResult`, and `Prism::LexCompat::Result`.
- Change reflection classes to have only a single `IntegerField` class and rename `DoubleField` to `FloatField`.
- Fall back to default `AR` and `CC` in `Makefile`.
- Use GC-able symbols for the syntax tree to avoid adding to the global symbol table.
- Fix a bug with karatsuba_multiply that would result in a stack overflow.
- Fix parser translation when looking for tokens with `srange_find`.

## [0.26.0] - 2024-04-18

### Added

- Add `Prism::Node::fields`, which returns a list of `Prism::Reflection::Field` objects representing the fields of the node class. This is useful in metaprogramming contexts.
- `Prism::Location#chop`, for removing the last byte from a location.
- The void statement warning is now implemented.
- The unreachable statement warning is now implemented.
- A syntax error has been added for block arguments on yields, e.g., `yield(&foo)`.

### Changed

- Better fidelity to `parser` when translating heredocs with interpolation.
- Fixed `RBI` and `RBS` types for `Prism::parse_*` signatures.
- Remove some incorrect warnings about unused local variables.
- More closely match CRuby error messages for global variables.
- Fix an issue with `parser` translation when line continuations are found in string literals.

## [0.25.0] - 2024-04-05

### Added

- `Prism::Translation::Ripper` is now able to mirror all of the Ripper APIs.
- `Prism::Location#leading_comments` and `Prism::Location#trailing_comments` is added.
- `Prism::Comment#slice` is added.
- Warn for writing literal values in conditional predicates.
- Check for `_POSIX_MAPPED_FILES` before using `mmap`.
- `Prism::ItParametersNode` is added, to support `-> { it }`.
- Parse integer and float literal values onto the tree.
- Warn on duplicated hash keys and duplicated when clauses.
- Ship much improved `RBI` and `RBS` types.
- Support for the `-p`, `-n`, `-a`, and `-l` command line switches.
- Warn on integer literals in flip-flops.
- Support BSD make.
- Add `Prism::WhenNode#then_keyword_loc`.
- Support custom allocation functions through the `PRISM_XALLOCATOR` define.
- Warn for certain keywrods at the end of the line.
- Provide `pm_visit_node`, a C visitor API.
- `Prism::parse_stream` is added, which works for any Ruby `IO` object.
- Provide flags for regular expression literals for their derived encoding.
- Provide flags for whether or not an interpolated string literal is frozen.
- Add `Prism::StringNode.mutable?` for when a string is explicitly mutable, to support delineating chilled strings.
- Warn for incorrect character literal syntax.
- Warn for chained comparison operators.
- Warn for `**` interpreted as an argument prefix.
- Warn for `&` interpreted as an argument prefix.
- `Prism::ShareableConstantNode` added to support ractors.
- Warn for frozen string literals found after tokens.
- Support `PRISM_BUILD_MINIMAL` to provide only the minimal necessary functionality to reduce the binary size.
- Handle CLRF inside heredocs, strings, and regular expressions.
- Mark inner strings in interpolated strings as frozen.
- Support the `-x` command line switch.
- Error messages now much more closely mirror CRuby.
- Provide syntax errors for invalid block exits (`break`, `next`, `retry`, and `yield`).
- Warn on unused local variables.
- Do not syntax error on default parameter values that only write to the parameter.

### Changed

- Many improvements to the compatibility with the `whitequark/parser` translation.
- Accept newlines before pattern terminators `)` or `]`.
- `Prism::Node#start_offset` and `Prism::Node#end_offset` are now much more efficient.
- Read files using `fread` instead of `mmap` when we're going to keep around the source through the Ruby API.
- Fix `Sexp#line_max` setting in the `seattlerb/ruby_parser` translation layer.
- Allow spaces before the encoding comment.

## [0.24.0] - 2024-02-15

### Added

- More support for `Prism::Translation::Ripper` is added.
- Support multiple versions for `Prism::Translation::Parser`.
- Improved memory usage in the FFI backend.
- Very large speed and memory improvements for creating the Ruby AST.

### Changed

- Fix location for empty symbol in hash key.
- Fix parsing a rescue modifier on the value of an assignment when the LHS is a method call with arguments and no parentheses.

## [0.23.0] - 2024-02-14

### Added

- More support for `Prism::RipperCompat` is added.
- A significantly faster offset cache for `Prism::Translation::Parser` is added for files with multibyte characters.
- `Prism::Translation::RubyParser` is added.
- `Prism::ConstantPathTarget#full_name` is added.
- `version: "3.4.0"` is added as an option that is an alias for `version: "latest"`.
- Four new APIs are added to `Prism::Location`:
  - `Prism::Location#start_code_units_offset`
  - `Prism::Location#end_code_units_offset`
  - `Prism::Location#start_code_units_column`
  - `Prism::Location#end_code_units_column`
- Invalid multibyte characters are now validated within strings, lists, and heredocs.

### Changed

- When defining `def !@`, the `name_loc` was previously only pointing to `!`, but now includes the `@`. The `name` is the same.
- `Prism::RipperCompat` has been moved to `Prism::Translation::Ripper`.
- Many of the error messages that prism produces have been changed to match the error messages that CRuby produces.

## [0.22.0] - 2024-02-07

### Added

- More support for `Prism::RipperCompat` is added.
- Support for Ruby 2.7 has been added, and the minimum Ruby requirement has been lowered to 2.7.

### Changed

- The error for an invalid source encoding has a new `:argument` level to indicate it raises an argument error.
- `BeginNode` nodes that are used when a class, singleton class, module, method definition, or block have an inline `rescue`/`ensure`/`else` now have their opening locations set to the beginning of the respective keyword.
- Improved error messages for invalid characters.
- `Prism.parse_file` and similar APIs will raise more appropriate errors when the file does not exist or cannot be mapped.
- Correctly handle the `recover` parameter for `Prism::Translation::Parser`.

## [0.21.0] - 2024-02-05

### Added

- Add the `pm_constant_pool_find` API for finding a constant.

### Changed

- Fixes for `Prism::Translation::Parser`.
  - Ensure all errors flow through `parser.diagnostics.process`.
  - Fix the find pattern node.
  - Fix block forwarding with `NumberedParametersNode`.
  - Ensure we can parse strings with invalid bytes for the encoding.
  - Fix hash pairs in pattern matching.
- Properly reject operator writes on operator calls, e.g., `a.+ -= b`.
- Fix multi-byte escapes.
- Handle missing body in `begin` within the receiver of a method call.

## [0.20.0] - 2024-02-01

### Added

- String literal hash keys are now marked as frozen as static literal.
- `IndexTargetNode` now always has the `ATTRIBUTE_WRITE` flag.
- `Call*Node` nodes now have an `IGNORE_VISIBILITY` flag.
- We now support the `it` default parameter.
- Errors and warnings now have levels associated with them.
- Symbols now have correct encoding flags.
- We have now merged `parser-prism` in, which provides translation to the `whitequark/parser` AST.
- We now emit errors for invalid method definition receivers.

### Changed

- We now emit errors on invalid pinned local variables.
- When passed scopes, it is now assumed that the innermost scope is the current binding.
- We now provide better error recovery for non terminated heredocs.
- Fix for `RationalNode#value` for non-decimal integers.
- Unary symbols `!@` and `~@` now unescape to `!` and `~`, respectively.
- `frozen_string_literal: false` now works properly.

### Removed

- We've removed the `locals_body_index` field.
- We've removed the `verbose` option on the various parse APIs. Warnings are now always emitted with their associated level so that consumers can decide how to handle them.

## [0.19.0] - 2023-12-14

### Added

- `ArrayNode` now has a `contains_splat?` flag if it has a splatted element in it.
- All of the remaining encodings have been implemented.
- Allow forwarding `&` in a method that has a `...` parameter.
- Many statements that are found in non-statement positions are being properly rejected now.
- Void values are now properly checked.
- Referencing a parameter in its own default value is now properly rejected.
- `DATA`/`__END__` is now parsed as its own field on parse result (`data_loc`) as opposed to as a comment.
- Blank `*` now properly forwards into arrays.
- `ImplicitRestNode` is introduced to represent the implicit rest of a destructure.
- We now support negative start lines.
- `StringNode#heredoc?`, `InterpolatedStringNode#heredoc?`, `XStringNode#heredoc?`, and `InterpolatedXStringNode#heredoc?` are introduced.
- `NumberedParametersNode` is introduced to represent the implicit set of parameters when numbered parameters are used.
- `Prism::parse_success?` and `Prism::parse_failure?` are introduced to bypass reifying the AST.
- We now emit a warning for constant assignments in method definitions.
- We now provide flags on strings and xstrings to indicate the correct encoding.
- The hash pattern `rest` field now more accurately parses `**` and `**nil`.
- The equality operators are now properly parsed as non-associative.

### Changed

- **BREAKING**: Many fields have changed positions within their nodes. This impacts the C API and the Ruby API if you are manually creating nodes through the initializer.
- **BREAKING**: Almost all of the error messages have been updated to begin with lowercase characters to match ruby/spec.
- Unterminated strings with only plain content are now always `StringNode` as opposed to `InterpolatedStringNode`
- **BREAKING**: Call node has been split up when it is in the target position into `CallTargetNode` and `IndexTargetNode`.

## [0.18.0] - 2023-11-21

### Added

- The `ParametersNode#signature` method is added, which returns the same thing as `Method#parameters`.
- Visitor functionality has been added to the JavaScript API.
- The `Node#to_dot` API has been added to convert syntax trees to Graphviz digraphs.
- `IfNode` and `UnlessNode` now have a `then_keyword_loc` field.
- Many more encodings are now supported.
- Some new `Location` APIs have been added for dealing with characters instead of bytes, which are: `start_character_offset`, `end_character_offset`, `start_character_column`, and `end_character_column`.
- A warning has been added for when `END {}` is used within a method.
- `ConstantPathNode#full_name{,_parts}` will now raise an error if the receiver of the constant path is not itself a constant.
- The `in` keyword and the `=>` operator now respect non-associativity.
- The `..` and `...` operators now properly respect non-associativity.

### Changed

- Previously `...` in blocks was accepted, but it is now properly rejected.
- **BREAKING**: `librubyparser.*` has been renamed to `libprism.*` in the C API.
- We now properly reject floats with exponent and rational suffixes.
- We now properly reject void value expressions.
- **BREAKING**: The `--disable-static` option has been removed from the C extension.
- The rescue modifier keyword is now properly parsed in terms of precedence.
- We now properly reject defining a numbered parameter method.
- **BREAKING**: `MatchWriteNode` now has a list of `targets`, which are local variable target nodes. This is instead of `locals` which was a constant list. This is to support writing to local variables outside the current scope. It has the added benefit of providing location information for the local variable targets.
- **BREAKING**: `CaseNode` has been split into `CaseNode` and `CaseMatchNode`, the latter is used for `case ... in` expressions.
- **BREAKING**: `StringConcatNode` has been removed in favor of using `InterpolatedStringNode` as a list.

## [0.17.1] - 2023-11-03

### Changed

- Do not use constant nesting in RBI files.

## [0.17.0] - 2023-11-03

### Added

- We now properly support forwarding arguments into arrays, like `def foo(*) = [*]`.
- We now have much better documentation for the C and Ruby APIs.
- We now properly provide an error message when attempting to assign to numbered parameters from within regular expression named capture groups, as in `/(?<_1>)/ =~ ""`.

### Changed

- **BREAKING**: `KeywordParameterNode` is split into `OptionalKeywordParameterNode` and `RequiredKeywordParameterNode`. `RequiredKeywordParameterNode` has no `value` field.
- **BREAKING**: Most of the `Prism::` APIs now accept a bunch of keyword options. The options we now support are: `filepath`, `encoding`, `line`, `frozen_string_literal`, `verbose`, and `scopes`. See [the pull request](https://github.com/ruby/prism/pull/1763) for more details.
- **BREAKING**: Comments are now split into three different classes instead of a single class, and the `type` field has been removed. They are: `InlineComment`, `EmbDocComment`, and `DATAComment`.

## [0.16.0] - 2023-10-30

### Added

- `InterpolatedMatchLastLineNode#options` and `MatchLastLineNode#options` are added, which are the same methods as are exposed on `InterpolatedRegularExpressionNode` and `RegularExpressionNode`.
- The project can now be compiled with `wasi-sdk` to expose a WebAssembly interface.
- `ArgumentsNode#keyword_splat?` is added to indicate if the arguments node has a keyword splat.
- The C API `pm_prettyprint` has a much improved output which lines up closely with `Node#inspect`.
- Prism now ships with `RBS` and `RBI` type signatures (in the `/sig` and `/rbi` directories, respectively).
- `Prism::parse_comments` and `Prism::parse_file_comments` APIs are added to extract only the comments from the source code.

### Changed

- **BREAKING**: `Multi{Target,Write}Node#targets` is split up now into `lefts`, `rest`, and `rights`. This is to avoid having to scan the list in the case that there are splat nodes.
- Some bugs are fixed on `Multi{Target,Write}Node` accidentally creating additional nesting when not necessary.
- **BREAKING**: `RequiredDestructuredParameterNode` has been removed in favor of using `MultiTargetNode` in those places.
- **BREAKING**: `HashPatternNode#assocs` has been renamed to `HashPatternNode#elements`. `HashPatternNode#kwrest` has been renamed to `HashPatternNode#rest`.

## [0.15.1] - 2023-10-18

### Changed

- Fix compilation warning on assigning to bitfield.

## [0.15.0] - 2023-10-18

### Added

- `BackReferenceReadNode#name` is now provided.
- `Index{Operator,And,Or}WriteNode` are introduced, split out from `Call{Operator,And,Or}WriteNode` when the method is `[]`.

### Changed

- Ensure `PM_NODE_FLAG_COMMON_MASK` into a constant expression to fix compile errors.
- `super(&arg)` is now fixed.
- Ensure the last encoding flag on regular expressions wins.
- Fix the common whitespace calculation when embedded expressions begin on a line.
- Capture groups in regular expressions now scan the unescaped version to get the correct local variables.
- `*` and `&` are added to the local table when `...` is found in the parameters of a method definition.

## [0.14.0] - 2023-10-13

### Added

- Syntax errors are added for invalid lambda local semicolon placement.
- Lambda locals are now checked for duplicate names.
- Destructured parameters are now checked for duplicate names.
- `Constant{Read,Path,PathTarget}Node#full_name` and `Constant{Read,Path,PathTarget}Node#full_name_parts` are added to walk constant paths for you to find the full name of the constant.
- Syntax errors are added when assigning to a numbered parameter.
- `Node::type` is added, which matches the `Node#type` API.
- Magic comments are now parsed as part of the parsing process and a new field is added in the form of `ParseResult#magic_comments` to access them.

### Changed

- **BREAKING**: `Call*Node#name` methods now return symbols instead of strings.
- **BREAKING**: For loops now have their index value considered as part of the body, so depths of local variable assignments will be increased by 1.
- Tilde heredocs now split up their lines into multiple string nodes to make them easier to dedent.

## [0.13.0] - 2023-09-29

### Added

- `BEGIN {}` blocks are only allowed at the top-level, and will now provide a syntax error if they are not.
- Numbered parameters are not allowed in block parameters, and will now provide a syntax error if they are.
- Many more Ruby modules and classes are now documented. Also, many have been moved into their own files and autoloaded so that initial boot time of the gem is much faster.
- `PM_TOKEN_METHOD_NAME` is introduced, used to indicate an identifier that if definitely a method name because it has an `!` or `?` at the end.
- In the C API, arrays, assocs, and hashes now can have the `PM_NODE_FLAG_STATIC_LITERAL` flag attached if they can be compiled statically. This is used in CRuby, for example, to determine if a `duphash`/`duparray` instruction can be used as opposed to a `newhash`/`newarray`.
- `Node#type` is introduced, which returns a symbol representing the type of the node. This is useful for case comparisons when you have to compare against multiple types.

### Changed

- **BREAKING**: Everything has been renamed to `prism` instead of `yarp`. The `yp_`/`YP_` prefix in the C API has been changed to `pm_`/`PM_`. For the most part, everything should be find/replaceable.
- **BREAKING**: `BlockArgumentNode` nodes now go into the `block` field on `CallNode` nodes, in addition to the `BlockNode` nodes that used to be there. Hopefully this makes it more consistent to compile/deal with in general, but it does mean it can be a surprising breaking change.
- Escaped whitespace in `%w` lists is now properly unescaped.
- `Node#pretty_print` now respects pretty print indentation.
- `Dispatcher` was previously firing `_leave` events in the incorrect order. This has now been fixed.
- **BREAKING**: `Visitor` has now been split into `Visitor` and `Compiler`. The visitor visits nodes but doesn't return anything from the visit methods. It is suitable for taking action based on the tree, but not manipulating the tree itself. The `Compiler` visits nodes and returns the computed value up the tree. It is suitable for compiling the tree into another format. As such, `MutationVisitor` has been renamed to `MutationCompiler`.

## [0.12.0] - 2023-09-15

### Added

- `RegularExpressionNode#options` and `InterpolatedRegularExpressionNode#options` are now provided. These return integers that match up to the `Regexp#options` API.
- Greatly improved `Node#inspect` and `Node#pretty_print` APIs.
- `MatchLastLineNode` and `InterpolatedMatchLastLineNode` are introduced to represent using a regular expression as the predicate of an `if` or `unless` statement.
- `IntegerNode` now has a base flag on it.
- Heredocs that were previously `InterpolatedStringNode` and `InterpolatedXStringNode` nodes without any actual interpolation are now `StringNode` and `XStringNode`, respectively.
- `StringNode` now has a `frozen?` flag on it, which respects the `frozen_string_literal` magic comment.
- Numbered parameters are now supported, and are properly represented using `LocalVariableReadNode` nodes.
- `ImplicitNode` is introduced, which wraps implicit calls, local variable reads, or constant reads in omitted hash values.
- `YARP::Dispatcher` is introduced, which provides a way for multiple objects to listen for certain events on the AST while it is being walked. This is effectively a way to implement a more efficient visitor pattern when you have many different uses for the AST.

### Changed

- **BREAKING**: Flags fields are now marked as private, to ensure we can change their implementation under the hood. Actually querying should be through the accessor methods.
- **BREAKING**: `AliasNode` is now split into `AliasMethodNode` and `AliasGlobalVariableNode`.
- Method definitions on local variables is now correctly handled.
- Unary minus precedence has been fixed.
- Concatenating character literals with string literals is now fixed.
- Many more invalid syntaxes are now properly rejected.
- **BREAKING**: Comments now no longer include their trailing newline.

## [0.11.0] - 2023-09-08

### Added

- `Node#inspect` is much improved.
- `YARP::Pattern` is introduced, which can construct procs to match against nodes.
- `BlockLocalVariableNode` is introduced to take the place of the locations array on `BlockParametersNode`.
- `ParseResult#attach_comments!` is now provided to attach comments to locations in the tree.
- `MultiTargetNode` is introduced as the target of multi writes and for loops.
- `Node#comment_targets` is introduced to return the list of objects that can have attached comments.

### Changed

- **BREAKING**: `GlobalVariable*Node#name` now returns a symbol.
- **BREAKING**: `Constant*Node#name` now returns a symbol.
- **BREAKING**: `BlockParameterNode`, `KeywordParameterNode`, `KeywordRestParameterNode`, `RestParameterNode`, `DefNode` all have their `name` methods returning symbols now.
- **BREAKING**: `ClassNode#name` and `ModuleNode#name` now return symbols.
- **BREAKING**: `Location#end_column` is now exclusive instead of inclusive.
- `Location#slice` now returns a properly encoded string.
- `CallNode#operator_loc` is now `CallNode#call_operator_loc`.
- `CallOperatorAndWriteNode` is renamed to `CallAndWriteNode` and its structure has changed.
- `CallOperatorOrWriteNode` is renamed to `CallOrWriteNode` and its structure has changed.

## [0.10.0] - 2023-09-01

### Added

- `InstanceVariable*Node` and `ClassVariable*Node` objects now have their `name` returning a Symbol. This is because they are now part of the constant pool.
- `NumberedReferenceReadNode` now has a `number` field, which returns an Integer.

### Changed

- **BREAKING**: Various `operator_id` and `constant_id` fields have been renamed to `operator` and `name`, respectively. See [09d0a144](https://github.com/ruby/yarp/commit/09d0a144dfd519c5b5f96f0b6ee95d256e2cb1a6) for details.
- `%w`, `%W`, `%i`, `%I`, `%q`, and `%Q` literals can now span around the contents of a heredoc.
- **BREAKING**: All of the public C APIs that accept the source string now accept `const uint8_t *` as opposed to `const char *`.

## [0.9.0] - 2023-08-25

### Added

- Regular expressions can now be bound by `\n`, `\r`, and a combination of `\r\n`.
- Strings delimited by `%`, `%q`, and `%Q` can now be bound by `\n`, `\r`, and a combination of `\r\n`.
- `IntegerNode#value` now returns the value of the integer as a Ruby `Integer`.
- `FloatNode#value` now returns the value of the float as a Ruby `Float`.
- `RationalNode#value` now returns the value of the rational as a Ruby `Rational`.
- `ImaginaryNode#value` now returns the value of the imaginary as a Ruby `Complex`.
- `ClassNode#name` is now a string that returns the name of just the class, without the namespace.
- `ModuleNode#name` is now a string that returns the name of just the module, without the namespace.
- Regular expressions and strings found after a heredoc declaration but before the heredoc body are now parsed correctly.
- The serialization API now supports shared strings, which should help reduce the size of the serialized AST.
- `*Node#copy` is introduced, which returns a copy of the node with the given overrides.
- `Location#copy` is introduced, which returns a copy of the location with the given overrides.
- `DesugarVisitor` is introduced, which provides a simpler AST for use in tools that want to process fewer node types.
- `{ClassVariable,Constant,ConstantPath,GlobalVariable,InstanceVariable,LocalVariable}TargetNode` are introduced. These nodes represent the target of writes in locations where a value cannot be provided, like a multi write or a rescue reference.
- `UntilNode#closing_loc` and `WhileNode#closing_loc` are now provided.
- `Location#join` is now provided, which joins two locations together.
- `YARP::parse_lex` and `YARP::parse_lex_file` are introduced to parse and lex in one result.

### Changed

- When there is a magic encoding comment, the encoding of the first token's source string is now properly reencoded.
- Constants followed by unary `&` are now properly parsed as a call with a passed block argument.
- Escaping multi-byte characters in a string literal will now properly escape the entire character.
- `YARP.lex_compat` now has more accurate behavior when a byte-order mark is present in the file.
- **BREAKING**: `AndWriteNode`, `OrWriteNode`, and `OperatorWriteNode` have been split back up into their `0.7.0` versions.
- We now properly support spaces between the `encoding` and `=`/`:` in a magic encoding comment.
- We now properly parse `-> foo: bar do end`.

## [0.8.0] - 2023-08-18

### Added

- Some performance improvements when converting from the C AST to the Ruby AST.
- Two rust crates have been added: `yarp-sys` and `yarp`. They are as yet unpublished.

### Changed

- Escaped newlines in strings and heredocs are now handled more correctly.
- Dedenting heredocs that result in empty string nodes will now drop those string nodes from the list.
- Beginless and endless ranges in conditional expressions now properly form a flip flop node.
- `%` at the end of files no longer crashes.
- Location information has been corrected for `if/elsif` chains that have no `else`.
- `__END__` at the very end of the file was previously parsed as an identifier, but is now correct.
- **BREAKING**: Nodes that reference `&&=`, `||=`, and other writing operators have been consolidated. Previously, they were separate individual nodes. Now they are a tree with the target being the left-hand side and the value being the right-hand side with a joining `AndWriteNode`, `OrWriteNode`, or `OperatorWriteNode` in the middle. This impacts all of the nodes that match this pattern: `{ClassVariable,Constant,ConstantPath,GlobalVariable,InstanceVariable,LocalVariable}Operator{And,Or,}WriteNode`.
- **BREAKING**: `BlockParametersNode`, `ClassNode`, `DefNode`, `LambdaNode`, `ModuleNode`, `ParenthesesNode`, and `SingletonClassNode` have had their `statements` field renamed to `body` to give a hint that it might not be a `StatementsNode` (it could also be a `BeginNode`).

## [0.7.0] - 2023-08-14

### Added

- We now have an explicit `FlipFlopNode`. It has the same flags as `RangeNode`.
- We now have a syntax error when implicit and explicit blocks are passed to a method call.
- `Node#slice` is now implemented, for retrieving the slice of the source code corresponding to a node.
- We now support the `utf8-mac` encoding.
- Predicate methods have been added for nodes that have flags. For example `CallNode#safe_navigation?` and `RangeNode#exclude_end?`.
- The gem now functions on JRuby and TruffleRuby, thanks to a new FFI backend.
- Comments are now part of the serialization API.

### Changed

- Autotools has been removed from the build system, so when the gem is installed it will no longer need to go through a configure step.
- The AST for `foo = *bar` has changed to have an explicit array on the right hand side, rather than a splat node. This is more consistent with how other parsers handle this.
- **BREAKING**: `RangeNodeFlags` has been renamed to `RangeFlags`.
- Unary minus on number literals is now parsed as part of the literal, rather than a call to a unary operator. This is more consistent with how other parsers handle this.

## [0.6.0] - 2023-08-09

### Added

- 🎉 Initial release! 🎉

[unreleased]: https://github.com/ruby/prism/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/ruby/prism/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/ruby/prism/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ruby/prism/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ruby/prism/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ruby/prism/compare/v0.30.0...v1.0.0
[0.30.0]: https://github.com/ruby/prism/compare/v0.29.0...v0.30.0
[0.29.0]: https://github.com/ruby/prism/compare/v0.28.0...v0.29.0
[0.28.0]: https://github.com/ruby/prism/compare/v0.27.0...v0.28.0
[0.27.0]: https://github.com/ruby/prism/compare/v0.26.0...v0.27.0
[0.26.0]: https://github.com/ruby/prism/compare/v0.25.0...v0.26.0
[0.25.0]: https://github.com/ruby/prism/compare/v0.24.0...v0.25.0
[0.24.0]: https://github.com/ruby/prism/compare/v0.23.0...v0.24.0
[0.23.0]: https://github.com/ruby/prism/compare/v0.22.0...v0.23.0
[0.22.0]: https://github.com/ruby/prism/compare/v0.21.0...v0.22.0
[0.21.0]: https://github.com/ruby/prism/compare/v0.20.0...v0.21.0
[0.20.0]: https://github.com/ruby/prism/compare/v0.19.0...v0.20.0
[0.19.0]: https://github.com/ruby/prism/compare/v0.18.0...v0.19.0
[0.18.0]: https://github.com/ruby/prism/compare/v0.17.1...v0.18.0
[0.17.1]: https://github.com/ruby/prism/compare/v0.17.0...v0.17.1
[0.17.0]: https://github.com/ruby/prism/compare/v0.16.0...v0.17.0
[0.16.0]: https://github.com/ruby/prism/compare/v0.15.1...v0.16.0
[0.15.1]: https://github.com/ruby/prism/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/ruby/prism/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/ruby/prism/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/ruby/prism/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/ruby/prism/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/ruby/prism/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/ruby/prism/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/ruby/prism/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/ruby/prism/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/ruby/prism/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/ruby/prism/compare/d60531...v0.6.0
