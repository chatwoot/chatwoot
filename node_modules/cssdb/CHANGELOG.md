# Changes to cssdb

### 4.4.0 (March 7, 2019)

- Updated: Nesting Rules are now Stage 1! 🎉

### 4.3.0 (December 12, 2018)

- Added: `:blank` Empty-Value Pseudo-Class
- Added: caniuse link for `:has()` Relational Pseudo-Class
- Added: JavaScript Library and PostCSS Plugin links for the `:blank`
  Empty-Value Pseudo-Class and the `:has()` Relational Pseudo-Class

### 4.2.0 (November 4, 2018)

- Added: Documentation links to MDN
- Added: `color-adjust` Property
- Added: `overscroll-behavior` Property
- Added: `prefers-color-scheme` Media Query
- Added: `prefers-reduced-motion` Media Query
- Added: `:in-range` and `:out-of-range` Pseudo-Classes
- Added: `:read-only` and `:read-write` selectors

This also updates the cssdb.org template and styles, using postcss-preset-env
to create and minifying cross-browser compatible css, improving font loading
and display, supporting RTL displays, and adding MDN documentation.

### 4.1.1 (October 28, 2018)

- Added: caniuse link for `overflow` shorthand property

### 4.1.0 (October 28, 2018)

- Added: Double Position Gradients

### 4.0.0 (October 23, 2018)

- Changed: `:something()` is now `:where()` and moved from Stage 2 to Stage 1

### 3.2.1 (August 31st, 2018)

- Updated: caniuse-like browser statistics for Custom Environment Variables

I really wish caniuse would start adding some of these.

### 3.2.0 (August 30th, 2018)

- Removed: Rejected `color-mod()` function
- Updated: Overflow shorthand is now Stage 2
- Updated: caniuse-like browser statistics for Custom Environment Variables and
  Overflow Shorthand

### 3.1.0 (May 11th, 2018)

- Added: Polyfills for `lab-function` and `lch-function`

### 3.0.0 (May 10th, 2018)

- Changed: All stages from 1-4 to 0-4 to align with TC39
- Updated: Tests, badges, descriptions, and dependencies

### 2.2.0 (May 7th, 2018)

- Added: Place Properties as Stage 2
- Added: PostCSS plugin for Color Functional Notation
- Updated: Media Query Ranges to Stage 4

### 2.1.0 (May 1st, 2018)

- Added: Environment Variables as Stage 1
- Added: `overflow` Property as Stage 2
- Added: Gap Properties as Stage 4

### 2.0.0 (April 7th, 2018)

- Renamed: GitHub repository from `css-db` to `cssdb`, now aligning with npm
- Renamed: All feature IDs.
- Updated: Documentation.

Notes: The old feature IDs were problematic because they attempted to follow
specification section IDs, but some specifications weren’t aren’t always
covered by a single section, and many sections were inconsistently named.
Because there was no pattern one could predict for any of the headings, a new
system was created; to **name** the feature and provide **context**. This meant
a feature ID like `css-cascade-all-shorthand` became `all-property`, and
`css-fonts-propdef-font-variant` became `font-variant-property`, etc. This
greatly simplified all of the feature IDs and allowed for more predictive
naming moving forward.

### 1.6.0 (February 18th, 2018)

- Added: Break Properties

### 1.5.2 (February 18th, 2018)

- Updated: `:focus-within` polyfills

### 1.5.1 (February 17th, 2018)

- Fixed: `:focus-visible` and `:focus-within` title syntax

### 1.5.0 (January 22th, 2018)

- Changed: Use the latest published specification URL whenever possible
- Changed: Upgrade Color #RRGGBBAA Notation to Stage 3
- Changed: Upgrade Color gray() Function to Stage 3
- Changed: Upgrade Color color-mod() Function to Stage 3
- Changed: Upgrade Color hwb() Function to Stage 3
- Changed: Downgrade Custom Properties to Stage 4
- Fixed: Color hwb() Function example
- Fixed: the Color rebeccapurple PostCSS Plugin URL

### 1.4.0 (January 16th, 2018)

- Changed: polyfill for `css-color-modifying-colors`

### 1.3.0 (January 8th, 2018)

- Added: caniuse references for `css-logical` and `css-fonts-system-ui-def`
- Fixed: caniuse parsing for browser support

### 1.2.0 (January 8th, 2018)

- Fixed: specification identifiers for `css-color-hwb-notation`,
         `selectors-dir-pseudo`
- Fixed: Examples for Media Queries Custom Media Queries

### 1.1.0 (September 27th, 2017)

- Added: Image `image-set()` Function, Selector `:dir` Pseudo-Class,
         Selector `:any-link` Pseudo-Class, Text `overflow-wrap` Property,
         Font `system-ui` Family, Cascade `all` Property
- Added: caniuse identifiers
- Fixed: Examples for Nesting, Media Queries Ranges

### 1.0.0 (September 6th, 2017)

- Initial version
