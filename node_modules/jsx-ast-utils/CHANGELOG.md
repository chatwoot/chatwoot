Unreleased
==================

3.2.0 / 2020-12-16
==================
- [New] add support for fragment syntax (`<>`) (#108)
- [Fix] `TSNonNullExpression`: handle `ThisExpression`s (#108)
- [Deps] update `array-includes`, `object.assign`
- [Dev Deps] update `@babel/core`, `@babel/parser`, `eslint`, `eslint-config-airbnb-base`, `object.entries`, `object.fromentries`

3.1.0 / 2020-10-13
==================
- [New] add `TSNonNullExpression` (#105)
- [New] add `AssignmentExpression` (#106)
- [Dev Deps] update `eslint`

3.0.0 / 2020-10-06
==================
- [Breaking] Don't return node.start & node.end (#100)
- [Breaking] add `ChainExpression`; `CallExpression` now includes arguments (#102)
- [New] add `SequenceExpression` (#101)
- [Deps] update `object.assign`
- [Dev Deps] update `eslint`, `eslint-plugin-import`
- [Dev Deps] update `@babel/core`, `@babel/parser`, `eslint`, `eslint-plugin-import`
- [Tests] use proper `actual, expected` ordering for non-confusing failure messages

2.4.1 / 2020-06-11
==================
- [Fix] `expressions/TemplateLiteral`: use `.range[0]` instead of `.start`

2.4.0 / 2020-06-11
==================
- [New] Provide both range and start & end property on Node, support eslint v7 (#97)
- [Dev Deps] update `@babel/core`, `@babel/parser`, `eslint`, `eslint-config-airbnb-base`, `eslint-plugin-import`, `flow-parser`
- [meta] remove yarn registry from npmrc, so `npm publish` works

2.3.0 / 2020-05-24
==================
- [New] add nullish coalescing (#99)
- [New] add OptionalCallExpression (#99)
- [Deps] update `array-includes`
- [meta] add `safe-publish-latest`
- [Dev Deps] update `@babel/parser`, `babel-eslint`, `coveralls`, `eslint`, `eslint-config-airbnb-base`, `eslint-plugin-import`, `in-publish`, `object.entries`, `object.fromentries`, `rimraf`
- [Tests] on `node` `v14`; test all branches

2.2.3 / 2019-10-24
==================
- (fix) Fix crash on spread (#94)

2.2.2 / 2019-10-24
==================
- (improvement) Add support for retrieving props from a spread with object expression (#93)

2.2.1 / 2019-06-30
==================
- (improvement) Account for TypeCastExpression in the utils

2.2.0 / 2019-06-25
==================
- (fix) Fix getLiteralPropValue for TS-specific node types.
- (chore) upgrade dependencies.
- (improvement) Stop throwing errors when unknown AST nodes are encountered.
- (dev) CI changes.

2.1.0 / 2018-04-19
==================
- Fix undefined bug for template strings. #45
- Adding support for `objectRestSpread` within props #60
- Accommodate ExperimentalSpreadProperty in prop values #75
- Account for SpreadElement AST Nodes #76
- Support OptionalMemberExpression AST nodes #77
- Add support to Typescript's node types #72

2.0.1 / 2017-08-31
==================
- [fix] Add support for BindExpression


2.0.0 / 2017-07-07
==================
- [breaking] Remove undefined return from `propName` so it always returns a value.


1.4.1 / 2017-04-19
==================
- [fix] - Fixing fatal throw in `getPropValue` for `ArrowFunctionExpression`


1.4.0 / 2017-02-02
==================
- [new] Add eventHandlers and eventHandlersByType to API. These are the event names for DOM elements on JSX-using libraries such as React, inferno, and preact.


1.3.5 / 2016-12-14
==================
- [fix] Normalize literals "true" and "false" before converting to boolean in Literal prop value extractor.


1.3.4 / 2016-11-15
==================
- [fix] Recursively resolve JSXMemberExpression names for elementType. (i.e. `<Component.Render.Me />`). Fixes [#9](https://github.com/evcohen/jsx-ast-utils/issues/9)


1.3.3 / 2016-10-28
==================
- [fix] Add support for `ArrayExpression`.


1.3.2 / 2016-10-11
==================
- [fix] Add support for `UpdateExpression`.


1.3.1 / 2016-07-13
==================
- [fix] Add `JSXElement` to expression types to handle recursively extracting prop value.


1.3.0 / 2016-07-12
==================
- [new] Add support for `TaggedTemplateExpression`.


1.2.1 / 2016-06-15
==================
- [fix] Point to `lib` instead of `src` for root exports.


1.2.0 / 2016-06-15
==================
- [new] Export functions from root so they can be imported like the following: `require('jsx-ast-utils/{function}')`.


1.1.1 / 2016-06-12
==================
- [fix] Better support for expressions in `TemplateLiteral` extraction.


1.1.0 / 2016-06-10
==================
- [new] Support for namespaced element names.
- [new] Add `propName` to API to get correct name for prop.


1.0.1 / 2016-06-10
==================
- [fix] Return actual reserved words instead of string representations of them.


1.0.0 / 2016-06-09
==================
- Initial stable release
