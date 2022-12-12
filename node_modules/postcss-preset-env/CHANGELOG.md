# Changes to PostCSS Preset Env

### 6.7.0 (July 8, 2019)

- Fixed the issue of autoprefixer alerting an upcoming change to the API
- Updated `autoprefixer` to 9.6.1 (minor)
- Updated `browserslist` to 4.6.4 (minor)
- Updated `cssdb` to 4.4.0 (minor)
- Updated `caniuse-lite` to 1.0.30000981 (patch)
- Updated `postcss` to 7.0.17 (patch)
- Updated `postcss-color-hex-alpha` to 5.0.3 (patch)
- Updated `postcss-custom-media` to 7.0.8 (patch)
- Updated `postcss-custom-properties` to 8.0.11 (patch)

### 6.6.0 (February 28, 2019)

- Moved browserslist detection from using each input file per process to using
  the working directory on intialization, as was implied by the documentation.
  If fixing this previously undocumented behavior causes any harm to existing
  projects, it can be easily rolled back in a subsequent patch. For the
  majority of projects — those with a singular browserslist configuration and
  potentially many individually processed CSS files — we should expect reported
  build times around 35 seconds to drop to less than 2 seconds.
- Updated `browserslist` to 4.4.2 (minor)
- Updated `autoprefixer` to 9.4.9 (patch)
- Updated `caniuse-lite` to 1.0.30000939 (patch)
- Updated `postcss` to 7.0.14 (patch)
- Updated `postcss-attribute-case-insensitive` to 4.0.1 (patch)

### 6.5.0 (December 12, 2018)

- Added `css-blank-pseudo` polyfill
- Added `css-has-pseudo` polyfill
- Updated `autoprefixer` to 9.4.2 (minor)
- Updated `browserslist` to 4.3.5 (minor)
- Updated `caniuse-lite` to 1.0.30000918 (patch)
- Updated `css-prefers-color-scheme` to 3.1.1 (minor, patch for this project)
- Updated `cssdb` to 4.3.0 (minor)
- Updated `postcss` to 7.0.6 (patch)

### 6.4.0 (November 6, 2018)

- Fixed `exportTo` option to export Custom Media, Custom Properties, and Custom
  Selectors all to the same function, object, or file
- Added `css-prefers-color-scheme` 3.0.0 (major, non-breaking for this project)
- Updated `cssdb` to 4.2.0 (minor)

### 6.3.1 (November 5, 2018)

- Updated `caniuse-lite` to 1.0.30000905 (patch)
- Updated `postcss-custom-properties` to 8.0.9 (patch)

### 6.3.0 (October 28, 2018)

- Added `postcss-double-position-gradients` 1.0.0 (major, non-breaking for this project)
- Updated `autoprefixer` to 9.3.1 (minor)
- Updated `browserslist` to 4.3.4 (patch)
- Updated `caniuse-lite` to 1.0.30000899 (patch)
- Updated `cssdb` to 4.1.0 (major, non-breaking for this project)

### 6.2.0 (October 22, 2018)

- Updated `autoprefixer` to 9.2.1 (minor)
- Updated `browserslist` to 4.3.1 (minor)

### 6.1.2 (October 19, 2018)

- Updated `browserslist` to 4.2.1 (patch)
- Updated `caniuse-lite` to 1.0.30000893 (patch)
- Updated `postcss-custom-media` to 7.0.7 (patch)

### 6.1.1 (October 12, 2018)

- Updated: `postcss-custom-media` to 7.0.6 (patch)

### 6.1.0 (October 10, 2018)

- Added: `postcss-color-gray`
- Added: Passing `autoprefixer: false` disables autoprefixer
- Updated: `browserslist` to 4.2.0 (minor)
- Updated: `caniuse-lite` to 1.0.30000890 (patch)

### 6.0.10 (October 2, 2018)

- Updated: `postcss-custom-properties` to 8.0.8 (patch)

### 6.0.9 (October 2, 2018)

- Updated: `browserslist` to 4.1.2 (patch)
- Updated: `postcss` to 7.0.5 (patch)
- Updated: `postcss-custom-properties` to 8.0.7 (patch)

### 6.0.8 (October 1, 2018)

- Updated: `caniuse-lite` to 1.0.30000888 (patch)
- Updated: `postcss` to 7.0.4 (patch)

**Did you hear? PostCSS Preset Env is now part of Create React App!** 🎉

### 6.0.7 (September 23, 2018)

- Updated: `postcss` to 7.0.3 (patch)
- Updated: `postcss-custom-properties` to 8.0.6 (patch)

### 6.0.6 (September 23, 2018)

- Updated: `postcss-custom-media` to 7.0.4 (patch)

### 6.0.5 (September 23, 2018)

- Updated: `postcss-color-mod-function` to 3.0.3 (patch)

### 6.0.4 (September 23, 2018)

- Updated: `caniuse-lite` to 1.0.30000887 (patch)
- Updated: `postcss-color-mod-function` to 3.0.2 (patch)

### 6.0.3 (September 21, 2018)

- Updated: `caniuse-lite` to 1.0.30000885 (patch)
- Updated: `postcss-custom-properties` to 8.0.5 (patch)

### 6.0.2 (September 20, 2018)

- Fixed: Do not break on an empty `importFrom` object
- Fixed: Actually run `postcss-env-function`

### 6.0.1 (September 20, 2018)

- Fixed: Issue with the `system-ui` font family polyfill by replacing
  `postcss-font-family-system-ui` with an internal polyfill, at least until the
  problem with the original plugin is resolved.

### 6.0.0 (September 20, 2018)

- Added: Support for PostCSS 7+
- Added: Support for PostCSS Values Parser 2+
- Added: Support for PostCSS Selector Parser 5+
- Added: Support for Node 6+
- Updated: All 28 plugins

### 5.4.0 (July 25, 2018)

- Added: `toggle` option to override which features are enabled or disabled
- Deprecated: toggle features with `toggle`, not `features`

### 5.3.0 (July 24, 2018)

- Updated: `postcss-lab-function` to v1.1.0 (minor update)

### 5.2.3 (July 21, 2018)

- Updated: `postcss-color-mod-function` to v2.4.3 (patch update)

### 5.2.2 (July 13, 2018)

- Updated: `autoprefixer` to v8.6.5 (patch update)
- Updated: `caniuse-lite` to v1.0.30000865 (patch update)
- Updated: `postcss-color-functional-notation` to v1.0.2 (patch update)

### 5.2.1 (June 26, 2018)

- Updated: `caniuse-lite` to v1.0.30000859 (patch update)
- Updated: `postcss-attribute-case-insensitive` to v3.0.1 (patch update)

### 5.2.0 (June 25, 2018)

- Updated: `autoprefixer` to v8.6.3 (minor update)
- Updated: `caniuse-lite` to v1.0.30000858 (patch update)
- Updated: `postcss` to 6.0.23 (patch update)
- Updated: `postcss-nesting` to v6.0.0 (major internal update, non-breaking for this project)

### 5.1.0 (May 21, 2018)

- Added: `autoprefixer` option to pass options into autoprefixer
- Updated: `autoprefixer` to v8.5.0 (minor update)
- Updated: `browserslist` to v3.2.8 (patch update)
- Updated: `caniuse-lite` to v1.0.30000844 (patch update)
- Updated: `postcss-color-functional-notation` to v1.0.1 (patch update)

### 5.0.0 (May 11, 2018)

- Added: `autoprefixer`
- Added: `postcss-color-functional-notation`
- Added: `postcss-env-function`
- Added: `postcss-lab-function`
- Added: `postcss-place`
- Added: `postcss-gap-properties`
- Added: `postcss-overflow-shorthand`
- Updated: `cssdb` to v3.1.0 (major update)
- Updated: In conformance with cssdb v3, the default stage is now 2
- Updated: `postcss-attribute-case-insensitive` to v3.0.0 (major update)
- Updated: `postcss-pseudo-class-any-link` to v5.0.0 (major update)
- Updated: `postcss-image-set-function` to v2.0.0 (major update)
- Updated: `postcss-dir-pseudo-class` to v4.0.0 (major update)
- Updated: `postcss-color-rebeccapurple` to v3.1.0 (minor update)
- Updated: `postcss` to v6.0.22 (patch update)
- Updated: `browserslist` to v3.2.7 (patch update)
- Updated: `caniuse-lite` to v1.0.30000839 (patch update)

All plugins now conform to the latest stable releases of `postcss-value-parser`
v1.5.0 and `postcss-selector-parser` v4.0.0.

### 4.1.0 (April 23, 2018)

- Updated: `browserslist` to v3.2.5 (patch update)
- Updated: `caniuse-lite` to v1.0.30000830 (patch update)
- Updated: `postcss-apply` to v0.10.0 (minor update)
- Updated: `postcss-nesting` to v5.0.0 (major update, non-breaking for this project)

### 4.0.0 (April 7, 2018)

- Added: `postcss-focus-within`
- Updated: `postcss-focus-visible` to v3.0.0 (major update)
- Updated: `caniuse-lite` to v1.0.30000824 (patch update)
- Updated: `cssdb` to v2.0.0 (major update)
- Changed: All `specificationId` names to new `id` names for the `cssdb` update.

### 3.5.0 (April 5, 2018)

- Fixed: `selectors-matches-pseudo` mapping to allow `:matches` polyfilling
- Updated: `postcss-dir-pseudo-class` to v3.0.0 (major update, non-breaking for this project)
- Updated: `postcss-logical` to v1.1.1 (minor update)
- Updated: `postcss` to v6.0.21 (patch update)
- Updated: `browserslist` to v3.2.4 (patch update)
- Updated: `caniuse-lite` to v1.0.30000823 (patch update)

### 3.4.0 (March 18, 2018)

- Updated: `browserslist` to v3.2.0 (minor update)
- Updated: `postcss` to v6.0.20 (patch update)
- Updated: `postcss-image-set-polyfill` to `@csstools/postcss-image-set-function` (hopefully temporarily)

### 3.3.0 (March 16, 2018)

- Updated: `postcss-apply` to v0.9.0 (minor update)
- Updated: `browserslist` to v3.1.2 (patch update)
- Updated: `caniuse-lite` to v1.0.30000815 (patch update)
- Updated: distribution to cjs and es bundles

### 3.2.2 (February 27, 2018)

- Updated: `postcss-color-mod-function` to v2.4.2 (patch update)

### 3.2.1 (February 21, 2018)

- Updated: Use the latest tested version of all dependencies

### 3.2.0 (February 18, 2018)

- Added: `postcss-page-break` which has moved here from Autoprefixer

### 3.1.0 (February 17, 2018)

- Added: `postcss-focus-visible`

### 3.0.0 (February 16, 2018)

- Updated: `postcss-color-mod-function` to v2.4 (minor update)
- Updated: `postcss-custom-properties` to v7.0 (major update)

### 2.2.0 (February 14, 2018)

- Updated: `browserslist` to v3.1 (major update)
- Updated: `postcss-color-mod-function` to v2.3 (minor update)
- Improved: cleaned up one reusable variable and added a few tests

### 2.1.0 (January 22, 2018)

- Updated: `cssdb` to v1.5 (minor update)
- Updated: `postcss-color-mod-function` to v2.2 (major update)
- Updated: `postcss-font-family-system-ui` to v3.0 (repo update)

### 2.0.0 (January 16, 2018)

- Initial version

### 1.0.0 (December 20, 2017)

- Unsupported version accidentally published by a member of the community
