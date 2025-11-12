# Changes to PostCSS Custom Properties

### 13.2.0 (June 1, 2023)

- Do not generate fallback values when the rule is wrapped in `@supports (top: var(--f))`.

### 13.1.5 (April 10, 2023)

- Updated `@csstools/css-tokenizer` to `2.1.1` (patch)
- Updated `@csstools/css-parser-algorithms` to `2.1.1` (patch)
- Updated `@csstools/cascade-layer-name-parser` to `1.0.2` (patch)

### 13.1.4 (February 21, 2023)

- Fixed: exception on chained variable declarations.

### 13.1.3 (February 8, 2023)

- Fixed: exception on missing variables.

### 13.1.2 (February 7, 2023)

- Do not apply fallback values when these contain unresolvable custom properties.

### 13.1.1 (January 28, 2023)

- Improve `types` declaration in `package.json`

### 13.1.0 (January 24, 2023)

- Added: Support for Cascade Layers.
- Improve plugin performance (port of fixes in `v12.1.11`)

### 13.0.0 (November 14, 2022)

- Updated: Support for Node v14+ (major).
- Removed : `importFrom` feature (breaking).
- Removed : `exportTo` feature (breaking).
- Added support for local custom property declarations.

```css
.example {
	--a-value: 20px;
	margin: var(--a-value);
}

/* becomes */

.example {
	--a-value: 20px;
	margin: 20px;
	margin: var(--a-value);
}
```

### 12.1.11 (December 1, 2022)

- Improve plugin performance

### 12.1.10 (October 20, 2022)

- Fix how `preserve: false` interacts with logic around duplicate code (see `12.1.9`).

```css
:root {
	--my-order: 1;
}

.foo {
	order: 1;
	order: var(--my-order);
}

/* With `preserve: false` : */

.foo {
	order: 1;
}
```

### 12.1.9 (September 14, 2022)

- Prevent duplicate code generation.

```diff
.foo {
	order: 1;
	order: var(--my-order, 1);
}

/* becomes */

.foo {
	order: 1;
- 	order: 1;
	order: var(--my-order, 1);
}
```

### 12.1.8 (June 10, 2022)

- Remove some unneeded regular expressions.

### 12.1.7 (April 8, 2022)

- Fix racing condition that could happen when using other async PostCSS plugins ([#331](https://github.com/csstools/postcss-plugins/issues/331))

### 12.1.6 (April 5, 2022)

- Fix `var()` fallback value downgrades with value lists.

### 12.1.5 (March 19, 2022)

- Add deprecation notice for `importFrom` and `exportTo`

[see the discussion](https://github.com/csstools/postcss-plugins/discussions/192)

### 12.1.4 (January 31, 2022)

- Fix `.mjs` in `importFrom` when using `export default`
- Fix `.mjs` in `importFrom` on Windows

### 12.1.3 (January 17, 2022)

- Reset plugin state after each process. It is now safe to use the plugin multiple times for different processes or when watching.

### 12.1.2 (January 12, 2022)

- Fix TypeScript transpilation.
- Avoid throwing errors on unexpected option objects.

### 12.1.1 (January 12, 2022)

- Fix Node 12/14 compatibility

### 12.1.0 (January 12, 2022)

- Add `overrideImportFromWithRoot` option
- Allow `.mjs` in `importFrom`
- Converted to TypeScript
- Correct typings for plugin options
- Fix unicode support in custom property names

### 12.0.4 (January 7, 2022)

- Fixed an issue that was causing synchronous mode to not being able to pick and transform properties that were added as part of the PostCSS flow. ([#132](https://github.com/csstools/postcss-plugins/issues/132))

### 12.0.2 (January 2, 2022)

- Removed Sourcemaps from package tarball.
- Moved CLI to CLI Package. See [announcement](https://github.com/csstools/postcss-plugins/discussions/121).

### 12.0.1 (December 16, 2021)

- Changed: now uses `postcss-value-parser` for parsing.
- Updated: documentation

### 12.0.0 (September 17, 2021)

- Updated: Support for PostCS 8+ (major).
- Updated: Support for Node 12+ (major).

### 11.0.0 (January 12, 2021)

- Added: Support for PostCSS v8.

### 10.0.0 (September 18, 2020)

- Fixed: `url-regex` vulnerability ([#228](https://github.com/postcss/postcss-custom-properties/pull/228))
- Breaking Change: Node v10+ now required

### 9.2.0 (September 18, 2020)

- Added: Export variables to SCSS file ([#212](https://github.com/postcss/postcss-custom-properties/pull/212))
- Added: Support for ".pcss" file resolution in `importFrom` ([#211](https://github.com/postcss/postcss-custom-properties/pull/211))
- Fixed: Allow combined selectors ([#199](https://github.com/postcss/postcss-custom-properties/pull/199))
- Fixed: Bug with spaces and commas in value ([#222](https://github.com/postcss/postcss-custom-properties/pull/222))
- Fixed: `importFrom` priority ([#222](https://github.com/postcss/postcss-custom-properties/pull/222))

### 9.1.1 (February 20, 2020)

- Fixed: Preserve spaces in multi-part values ([#203](https://github.com/postcss/postcss-custom-properties/pull/203))

### 9.1.0 (July 15, 2019)

- Added: Support for preserving trailing comments within a declaration.

### 9.0.2 (July 15, 2019)

- Updated: `postcss-values-parser` to 3.0.5 (patch)

### 9.0.1 (June 20, 2019)

- Updated: `postcss-values-parser` to 3.0.4 (major)
- Updated: Node 8+ compatibility (major)

> This release is identical to v9.0.0, only `npm publish` failed to publish v9.0.0 and threw the following error:
> ```
> You cannot publish over the previously published versions: 9.0.0.
> ```
> I did not want this issue to distract me, and so I thoughtfully and impatiently published v9.0.0 as v9.0.1.

### 8.0.11 (June 20, 2019)

- Added: Synchronous transforms when async is unnecessary (thank @eteeselink)
- Fixed: Unexpected mutations to imported Custom Properties (thank @EECOLOR)
- Fixed: Transforms throwing over unknown Custom Properties

### 8.0.10 (April 1, 2019)

- Added: Support for ignoring lines and or blocks using
  `postcss-custom-properties` comments.
- Updated: `postcss` to 7.0.14 (patch)
- Updated: `postcss-values-parser` to 2.0.1 (patch)

### 8.0.9 (November 5, 2018)

- Fixed: Issue with duplicate custom property usage within a declaration

### 8.0.8 (October 2, 2018)

- Fixed: Issue with nested fallbacks

### 8.0.7 (October 2, 2018)

- Fixed: Issue with parsing custom properties that are not strings
- Updated: `postcss` to 7.0.5 (patch)

### 8.0.6 (September 21, 2018)

- Fixed: Issue with regular `:root` and `html` properties not getting polyfilled
- Updated: `postcss` to 7.0.3 (patch)

### 8.0.5 (September 21, 2018)

- Fixed: Issue with multiple `importFrom` not getting combined

### 8.0.4 (September 18, 2018)

- Fixed: Do not break on an empty `importFrom` object

### 8.0.3 (September 18, 2018)

- Updated: PostCSS Values Parser 2

### 8.0.2 (September 17, 2018)

- Fixed: Spacing is preserved before replaced variables.

### 8.0.1 (September 17, 2018)

- Fixed: Workaround issue in `postcss-values-parser` incorrectly cloning nodes.

### 8.0.0 (September 16, 2018)

- Added: New `exportTo` function to specify where to export custom properties to.
- Added: New `importFrom` option to specify where to import custom properties from.
- Added: Support for variables written within `html`
- Added: Support for PostCSS v7.
- Added: Support for Node v6+.
- Removed: `strict` option, as using the fallback value isn’t necessarily more valid.
- Removed: `preserve: "computed"` option, as there seems to be little use in preserving custom property declarations while removing all usages of them.
- Removed: `warnings` and `noValueNotifications` options, as this should be the job of a linter tool.
- Removed: `variables` option, which is now replaced by `importFrom`
- Removed: `appendVariables` option, which is now replaced by `exportTo`
- Fixed: Custom Properties in `:root` are not also transformed.
- Fixed: Declarations that do not change are not duplicated during preserve.

### 7.0.0 (February 16, 2018)

- Changed: `preserve` option defaults as `true` to reflect the browser climate
- Changed: `warnings` option defaults to `false` to reflect the browser climate

### 6.3.1 (February 16, 2018)

- Reverted: `preserve` and `warnings` option to be added in major release

### 6.3.0 (February 15, 2018)

- Fixed: `var()` captures strictly `var()` functions and not `xvar()`, etc
- Fixed: `var()` better captures whitespace within the function
- Fixed: comments within declarations using `var()` are now preserved
- Changed: `preserve` option defaults as `true` to reflect the browser climate
- Changed: `warnings` option defaults to `false` to reflect the browser climate
- Updated documentation

### 6.2.0 (October 6, 2017)

- Added: `noValueNotifications` option (#71)
- Fixed: Typo in `prefixedVariables` variable name (#77)

### 6.1.0 (June 28, 2017)

- Added: Let "warnings" option silence all warnings
([#67](https://github.com/postcss/postcss-custom-properties/pull/67))
- Dependencies update (postcss, balanced-match)

### 6.0.1 (May 15, 2017)

- Fixed: incorrect export ([#69](https://github.com/postcss/postcss-custom-properties/issues/69))

### 6.0.0 (May 12, 2017)

- Added: compatibility with postcss v6.x

### 5.0.2 (February 1, 2017)

- Minor dependency update
  ([#57](https://github.com/postcss/postcss-custom-properties/pull/57))

### 5.0.1 (April 22, 2016)

- Fixed: trailing space after custom property name causes duplicate empty
  property
  ([#43](https://github.com/postcss/postcss-custom-properties/pull/43))

### 5.0.0 (August 25, 2015)

- Removed: compatibility with postcss v4.x
- Added: compatibility with postcss v5.x

### 4.2.0 (July 21, 2015)

- Added: `warnings` option allows you to disable warnings.
([cssnext#186](https://github.com/cssnext/cssnext/issues/186))

### 4.1.0 (July 14, 2015)

- Added: plugin now returns itself in order to expose a `setVariables` function
that allow you to programmatically change the variables.
([#35](https://github.com/postcss/postcss-custom-properties/pull/35))

### 4.0.0 (June 17, 2015)

- Changed: messages and exceptions are now sent using postcss message API.

### 3.3.0 (April 8, 2015)

- Added: `preserve` now support `"computed"` so only preserve resolved custom properties (see new option below)
- Added: `appendVariables` allows you (when `preserve` is truthy) to append your variables as custom properties
- Added: `strict: false` allows your to avoid too many fallbacks added in your CSS.

### 3.2.0 (03 31, 2015)

- Added: JS defined variables are now resolved too ([#22](https://github.com/postcss/postcss-custom-properties/issues/22))

### 3.1.0 (03 16, 2015)

- Added: variables defined in JS are now automatically prefixed with `--`
  ([0691784](https://github.com/postcss/postcss-custom-properties/commit/0691784ed2218d7e6b16da8c4df03e2ca0c4798c))

### 3.0.1 (February 6, 2015)

- Fixed: logs now have filename back ([#19](https://github.com/postcss/postcss-custom-properties/issues/19))

### 3.0.0 (January 20, 2015)

- Changed: upgrade to postcss 4 ([#18](https://github.com/postcss/postcss-custom-properties/pull/18))
- Removed: some code that seems to be useless ([16ff3c2](https://github.com/postcss/postcss-custom-properties/commit/16ff3c22fe0563a1283411d7866791966fff4c58))

### 2.1.1 (December 2, 2014)

- Fixed: issue when multiples undefined custom properties are referenced ([#16](https://github.com/postcss/postcss-custom-properties/issues/16))

### 2.1.0 (November 25, 2014)

- Added: enhanced exceptions & messages

### 2.0.0 (November 12, 2014)

- Changed: upgrade to postcss 3

### 1.0.2 (November 4, 2014)

- Fixed: more clear message for warning about custom prop used in non top-level :root

### 1.0.1 (November 3, 2014)

- Fixed: warning about custom prop used in non :root

### 1.0.0 (November 2, 2014)

- Added: warning when a custom prop is used in another place than :root
- Added: handle !important

### 0.4.0 (September 30, 2014)

- Added: JS-defined properties override CSS-defined

### 0.3.1 (August 27, 2014)

- Added: nested custom properties usages are now correctly resolved
- Changed: undefined var doesn't throw error anymore (just a console warning) & are kept as is in the output

### 0.3.0 (August 26, 2014)

- Changed: fallback now are always added by default ([see why](http://www.w3.org/TR/css-variables/#invalid-variables))
- Changed: `map` option renamed to `variables`

### 0.2.0 (August 22, 2014)

- Added: `map` option
- Changed: GNU style error message

### 0.1.0 (August 1, 2014)

✨ First release based on [rework-vars](https://github.com/reworkcss/rework-vars) v3.1.1
