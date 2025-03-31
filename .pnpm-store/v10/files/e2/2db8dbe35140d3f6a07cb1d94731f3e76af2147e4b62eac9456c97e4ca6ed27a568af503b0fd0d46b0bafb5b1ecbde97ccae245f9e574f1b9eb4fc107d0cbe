# Changes to PostCSS Custom Selectors

### 7.1.3 (April 10, 2023)

- Updated `@csstools/css-tokenizer` to `2.1.1` (patch)
- Updated `@csstools/css-parser-algorithms` to `2.1.1` (patch)
- Updated `@csstools/cascade-layer-name-parser` to `1.0.2` (patch)

### 7.1.2 (February 8, 2023)

- Reduce the amount of duplicate fallback CSS.

### 7.1.1 (January 28, 2023)

- Improve `types` declaration in `package.json`

### 7.1.0 (January 24, 2023)

- Added: Support for Cascade Layers.

### 7.0.0 (November 14, 2022)

- Updated: Support for Node v14+ (major).
- Removed: `importFrom` feature (breaking).
- Removed: `exportTo` feature (breaking).
- Fixed: follow the specification and use `:is()` in transformed selectors (breaking).
- Added: Support for `@scope` and `@container` as parent rules of `@custom-selector`.
- Fixed: Do not throw when a selector is invalid, show a warning instead.

```diff
@custom-selector :--heading h1, h2, h3;

article :--heading + p {
	margin-top: 0;
}

/* becomes */

- article h1 + p,article h2 + p,article h3 + p {
+ article :is(h1, h2, h3) + p {
	margin-top: 0;
}
```

### 6.0.3 (June 4, 2022)

- Fixed: allow any valid ident in custom selectors (`@custom-selector :--🧑🏾‍🎤 .singer`)

### 6.0.2 (June 3, 2022)

- Fixed: prevent duplicate rules when custom selectors are not defined
- Fixed: selectors not resolving when using with other features like nesting

### 6.0.1 (June 3, 2022)

- Fixed: invalid whitespace (https://github.com/csstools/postcss-custom-selectors/pull/55)

### 6.0.0 (January 12, 2021)

- Added: Support for PostCSS v8
- Added: Support for Node v10+
- Fixed: importing from multiple sources (https://github.com/postcss/postcss-custom-selectors/pull/42)

### 5.1.2 (September 20, 2018)

- Fixed: Do not break on an empty `importFrom` object

### 5.1.1 (September 18, 2018)

- Fixed: Selectors like `.foo:--h1` become `h1.foo` instead of `.fooh1`

### 5.1.0 (September 12, 2018)

- Added: New `exportTo` function to specify where to export custom selectors
- Updated: `importFrom` option to support passing it a function

### 5.0.0 (September 7, 2018)

- Added: New `preserve` option to preserve custom selectors and rules using them
- Added: New `importFrom` option to specify where to import custom selectors
- Added: Support for PostCSS v7
- Added: Support for Node v6+

### 4.0.1 (May 15, 2017)

- Fixed: incorrect export

### 4.0.0 (May 12, 2017)

- Added: compatibility with postcss v6.x

### 3.0.0 (August 25, 2015)

- Removed: compatibility with postcss v4.x
- Added: compatibility with postcss v5.x

### 2.3.0 (July 14, 2015)

* Fixed: Nested/mixed selectors now works correctly
(https://github.com/postcss/postcss-custom-selectors/issues/19)
* Added: `transformMatches` option to limit transformation to :matches()
replacements.

### 2.2.0 (June 30, 2015)

* Fixed: No more useless warnings for undefined non custom selectors
(https://github.com/postcss/postcss-custom-selectors/issues/22)
* Changed: warnings now use PostCSS message API

### 2.1.1 (June 30, 2015)

* Fixed: the lineBreak option keeping the selectors indent
(https://github.com/postcss/postcss-custom-selectors/issues/18)
* Fixed: the tip of an undefined selector
(https://github.com/postcss/postcss-custom-selectors/issues/20)

### 2.1.0 (June 4, 2015)

* Changed: use PostCSS 4.1 plugin API
(https://github.com/postcss/postcss-custom-selectors/issues/13)

### 2.0.1 (June 3, 2015)

* Fixed: `(foo, bar)` conversion error exists in the selector

### 2.0.0 (May 29, 2015)

* Removed: no longer support `::` or `--` to defined a custom selectors,
you must use the syntax `:--` to define it.
(https://github.com/postcss/postcss-custom-selectors/issues/6)
* Fixed: two or more consecutive hyphens in selector don't output `undefined`
(https://github.com/postcss/postcss-custom-selectors/issues/14)


### 1.1.1 (April 6, 2015)

* Fixed: add support for multilines definition

### 1.1.0 (December 6, 2014)

* Added: "lineBreak" option

### 1.0.0 (December 6, 2014)

* First release
