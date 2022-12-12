# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [10.0.0] - 2019-09-11
### Security
- Fix quadratic parse time for some combinations of pairs, #583. Algorithm is
  now similar to one in reference implementation.

### Changed
- Minor internal structs change, to make pairs parse more effective (cost is
  linear now). If you use external "pairs" extensions, you need sync those with
  "official ones". Without update, old code will work, but can cause invalid
  result in rare case. This is the only reason of major version bump. With high probability you don't need to change your code, only update version dependency.
- Updated changelog format.
- Deps bump.


## [9.1.0] - 2019-08-11
### Changed
- Remove extra characters from line break check. Leave only 0x0A & 0x0D, as in
  CommonMark spec, #581.

## [9.0.0] - 2019-07-09
### Changed
- Updated CM spec compatibility to 0.29.
- Update Travis-CI node version to actual (8 & latest).
- Deps bump.


## [8.4.2] - 2018-02-15
### Fixed
- Fix `--no-html` CLI option, #476.


## [8.4.1] - 2018-02-15
### Fixed
- Fix smartquotes around softbreaks, #430.


## [8.4.0] - 2017-08-24
### Changed
- Updated CM spec compatibility to 0.28.


## [8.3.2] - 2017-08-03
### Fixed
- Fix blockquote termination inside lists, #386.


## [8.3.1] - 2017-03-06
### Fixed
- Fix blockquote termination by list item, #338.


## [8.3.0] - 2017-02-16
### Changed
- Remove tabs at the beginning of the line in paragraphs.
- Better error message for bad input type, #324.

### Fixed
- Fix table indentation issues, #325, #224.
- Fix blockquote termination inside indented lists, #329.


## [8.2.2] - 2016-12-15
### Added
- Add `-o` / `--output` option to CLI, #312.


## [8.2.1] - 2016-12-02
### Fixed
- Add missed h2..h6 to whitelisted block tags.


## [8.2.0] - 2016-12-01
### Changed
- Updated CM spec compatibility to 0.27 (no significant changes).

### Fixed
- Fix backticks handle inside tables, #303.
- Fix edge case for fenced blocks with `~~~` in info, #301.
- Fix fallback to reference if link is not valid, #302.


## [8.1.0] - 2016-11-03
### Changed
- Make link parse helpers (`md.helpers`) pluggable, #299.


## [8.0.1] - 2016-10-18
### Fixed
- Tables: allow tab characters in markup


## [8.0.0] - 2016-09-16
### Changed
- Benchmarks src cleanup.
- Remove testing in old nodes (but still use es5).
- Updated CM spec compatibility to 0.26 (see list below):
- Two consecutive newlines no longer terminate a list.
- Ordered list terminating a paragraph can now only start with 1.
- Adjust emphasis algorithm (`*foo**bar**baz*` is now parsed as `<strong>`
  inside `<em>`).
- Fix tab width calculation inside lists and blockquotes.


## [7.0.1] - 2016-08-16
### Fixed
- Fence renderer: fix concat of class array, #276.
- Code renderer: do not render double space before attrs, #275.
- Replacer: disable replacements inside autolinks, #272.


## [7.0.0] - 2016-06-22
### Changed
- Bump `linkify-it` dependency to 2.0.0.  `---` no longer terminates
  autodetected links by default. `md.linkifier.set('---', true)` will return old
  behaviour.
- Major version bumped, because internals or `linkify-it` was changed.
  You will not be affected anyhow, if not used direct access to
  `require('linkify-it/re')` for customizations.


## [6.1.1] - 2016-06-21
### Changed
- Render `code_inline` & `code_block` attributes if exist.


## [6.1.0] - 2016-06-19
### Changed
- Updated `fence` renderer to not mutate token. Token stream should be
  immutable after renderer call.


## [6.0.5] - 2016-06-01
### Fixed
- Process `\r` the same way as `\n` and `\r\n\`, #252.


## [6.0.4] - 2016-05-30
### Added
- Added `Token.attrGet()` method for convenience, #251.


## [6.0.3] - 2016-05-30
### Security
- Security fix: possible ReDOS in `linkify-it` (forced bump of `linkify-it` &
  `uc-micro` dependencies). New installs will use fixed packages automatically,
  but we bumped `markdown-it` version for sure & for web builds.


## [6.0.2] - 2016-05-16
### Fixed
- Fix: should not escape twice content of image alt attribute, #246.


## [6.0.1] - 2016-04-02
### Fixed
- Improve support of missing values in tables, #224.


## [6.0.0] - 2016-02-11
### Changed
- Maintenance release. Version bump caused by notable changes in CM spec
  (multiline setext headers, no spaces inside links, ...). API was not changed.
- Fit CM 0.24 spec requirements.

### Fixed
- Fixed nesting limit check in inline blocks, #197.
- Fixed posible tail loss in CLI ouput.


## [5.1.0] - 2016-01-07
### Added
- Token: added `.attrSet()` & `.attrJoin()` methods.
- Highlighter: allow wrapper override (if result starts with "<pre").


## [5.0.3] - 2016-01-04
### Fixed
- Allow single column and mismatched columns count in tables.
- Smartquotes: take into account adjacent tokens.
- Fill `content` property in image token with `alt` source.


## [5.0.2] - 2015-11-20
### Fixed
- Fix meta information (`token.markup` and `token.info`) for autolink tokens.


## [5.0.1] - 2015-10-30
### Fixed
- Improved tables compatibility with github, #120.


## [5.0.0] - 2015-10-05
### Changed
- Internal API change. Due to new CM spec requirements, we had to update
  internals. That should not touch ordinary users, but can affect some external
  plugins. If you are plugin developper - see migration guide:
  https://github.com/markdown-it/markdown-it/blob/master/docs/5.0_migration.md.
- Updated CM spec compatibility to 0.22 (see list below).
- Keep tabs (don't replace with spaces).
- Don't wrap iframes with paragraphs.
- Rewritten emphasis algorithm.

### Fixed
- Fix closure compiler collisions (don't use reserved words), #159.


## [4.4.0] - 2015-07-18
### Changed
- Updated HTML blocks logic to CM 0.21 spec.
- Minor fixes.


## [4.3.1] - 2015-07-15
### Security
- Fix class name injection in fence renderer.

### Fixed
- Allow numbered lists starting from zero.


## [4.3.0] - 2015-06-29
### Changed
- `linkify-it` dependency update (1.2.0). Now accepts dash at the end of links.


## [4.2.2] - 2015-06-10
### Changed
- CM spec 0.20.

### Added
- Added support for multichar substituition in smartquites, #115.

### Fixed
- Fixed code block render inside blockquites, #116.
- Doc fixes.


## [4.2.1] - 2015-05-01
### Changed
- Minor emphasis update to match CM spec 0.19.


## [4.2.0] - 2015-04-21
### Changed
- Bumped [linkify-it](https://github.com/markdown-it/linkify-it) version to
  1.1.0. Now links with IP hosts and without protocols are not linkified by
  default, due possible collisions with some version numbers patterns (0.5.0.0).
  You still can return back old behaviour by `md.linkify.set({ fuzzyIP: true })`.


## [4.1.2] - 2015-04-19
### Changed
- Bumped linkifier version. More strict 2-chars tald support for links without
  schema. Should not linkify things like `io.js` and `node.js`.


## [4.1.1] - 2015-04-15
### Fixed
- Improved pipe chars support in table cells, #86 (thanks to @jbt).


## [4.1.0] - 2015-03-31
### Security
- Disabled `data:` URLs by default (except some image mimes), to avoid
  possible XSS. Version bumped, because features changed (formally). If you did
  not used `data:` URLs, consider this version as 4.0.4 (no API changes).

### Changed
- Simplified link validator code. Now more easy to understand and to copy
  into your projects for customization.


## [4.0.3] - 2015-03-25
### Changed
- Updated linkifier.
- Smartquotes rule cleanup (#76).

### Fixed
- Fixed replacements rule bug in PhantomJS (#77).


## [4.0.2] - 2015-03-22
### Fixed
- Fixed emphasis `marker` fields in tokens (#69).
- Fixed html block tokens with numbers in name (#74).


## [4.0.1] - 2015-03-13
### Added
- Added custom container plugin demo.

### Changed
- Updated `linkify-it` version.


## [4.0.0] - 2015-03-11
### Changed
- Breaking internal API changes. See [v4 migration notes](https://github.com/markdown-it/markdown-it/blob/master/docs/4.0_migration.md). In usual case you will need to update plugins.
- Token internals changed
- Unified the most of renderer methods.
- Changed tokens creation - use `state.push(...)` (see sources)
- Moved `normalizeUrl()` to root class as `.normalizeLink()` &
  added `normalizeLinkText()` method.
- Moved `.validateUrl()` to root class and simplified logic - no more need to
  replace entities.
- Joined md unescape & replace entities logic to `utils.unescapeAll()`.
- Removed `replaceEntities()` in `utils`.
- `md.utils.lib` now exposes useful libs for plugins.
- Use entities data from external package.

### Fixed
- Fixed emphasis regression, caused by CM v0.18 spec (#65).


## [3.1.0] - 2015-03-05
### Changed
- Spec conformance update to 0.18.
- Significantly improved autolinking quality (use `linkify-it` package), #2.

### Fixed
- Rewritten links normalizer to solve different edge cases (use `mdurl`
  package), #29.
- Moved link title entities replace out of renderer.
- Fixed escaped entities in links (`foo\&amp;/bar`).
- Improved smartquotes logic, #61.


## [3.0.7] - 2015-02-22
### Added
- Added basic CLI support.

### Changed
- Use external package for unicode data (punctuation).

### Fixed
- Added \v \f to valid whitespaces.
- Match table columns count by header.


## [3.0.6] - 2015-02-12
### Added
- Sync scroll result => source in demo.

### Changed
- Moved `normalizeReference()` to utils.

### Fixed
- Fixed hang on long vertical list of links. Appeared in 3.0.5. See #54 for
  details. Thanks to @fengmk2 for report!
- Table lines now can have escaped pipe char `\|` (#5).


## [3.0.5] - 2015-02-06
### Changed
- Significantly improved tests coverage (with dead code removal and other
  related things).

### Fixed
- Fixed link validator - could skip some kind of javascript links with uppercase
  digital entities (thanks to @opennota)


## [3.0.4] - 2015-01-13
### Changed
- Improved errors processing in url normalizer (for broken sequences).
- Improved nesting limit processing in inline parser.
- Reorganized tests & improved coverage.
- Show inline diffs for failed tests.


## [3.0.3] - 2015-01-11
### Fixed
- Fixed punctuation check in emphasis.


## [3.0.2] - 2015-01-09
### Fixed
- Allow dashes in HTML tag names (needed for custom HTML tags).


## [3.0.1] - 2015-01-07
### Changed
- Added # to terminator chars.

### Fixed
- Improved link encoder - fix invalid surrogates to avoid errors.


## [3.0.0] - 2015-01-04
### Changed
- Big split. All "rare" rules moved to external plugins (deflist, abbr, footnote,
  sub, sup, ins, mark).
- Updated CM spec conformance to v0.15 (better unicode support).
- Added `md` (parser instance) link to all state objects (instead of former
  options/parser).
- References/Footnotes/Abbrs moved to `block` chain.
- Input normalization moved to `core` chain.
- Splitted links and images to separate rules.
- Renamed some rules.
- Removed `full` preset. Not needed anymore.
- enable/disable methods now throw by default on invalid rules (exceptions can
  be disabled).
- Replace NULL characters with 0xFFFD instead of strip.
- Removed custom fences sugar (overcomplication).
- Rewritten link components parse helpers.
- More functions in `md.utils`.

### Fixed
- Fixed inline html comments & cdata parse.


## [2.2.1] - 2014-12-29
### Added
- Added development info.

### Changed
- .use() now pass any number of params to plugins.

### Fixed
- Fixed line breaks in definitions lists.


## [2.2.0] - 2014-12-28
### Added
- API docs.
- Added 'zero' preset.

### Changed
- Updated CM spec conformance to v0.13.

### Fixed
- Fixed several crashes, when some basic rules are disabled
  (block termination check, references check).


## [2.1.3] - 2014-12-24
### Added
- Added curring to `set`/`configure`/`enable`/`disable` methods.

### Changed
- Demo rework - now can include plugins.
- Docs update.


## [2.1.2] - 2014-12-23
### Changed
- Exposed helpers into parser instances (for plugins).
- Removed utils from global export - been in instances seems enougth.
- Refactored demo & added markdown-it-emoji to it.


## [2.1.1] - 2014-12-22
### Changed
- Refreshed browser builds, missed in prev release.
- Minor changes.


## [2.1.0] - 2014-12-21
### Changed
- Separated method to enable rules by whitelist (enableOnly).
- Changed second param of enable/disable ruler methods.
- Shortcuts in main class for bulk enable/disable rules.
- ASCII-friendly browserified files.
- Separate package for spec tests.


## [2.0.0] - 2014-12-20
### Changed
- New project name & home! Now it's `markdown-it`,
- Sugar for constructor call - `new` is not mandatory now.
- Renamed presets folder (configs -> presets).


[10.0.0]: https://github.com/markdown-it/markdown-it/compare/9.1.0...10.0.0
[9.1.0]: https://github.com/markdown-it/markdown-it/compare/9.0.1...9.1.0
[9.0.1]: https://github.com/markdown-it/markdown-it/compare/9.0.0...9.0.1
[9.0.0]: https://github.com/markdown-it/markdown-it/compare/8.4.2...9.0.0
[8.4.2]: https://github.com/markdown-it/markdown-it/compare/8.4.1...8.4.2
[8.4.1]: https://github.com/markdown-it/markdown-it/compare/8.4.0...8.4.1
[8.4.0]: https://github.com/markdown-it/markdown-it/compare/8.3.2...8.4.0
[8.3.2]: https://github.com/markdown-it/markdown-it/compare/8.3.1...8.3.2
[8.3.1]: https://github.com/markdown-it/markdown-it/compare/8.3.0...8.3.1
[8.3.0]: https://github.com/markdown-it/markdown-it/compare/8.2.2...8.3.0
[8.2.2]: https://github.com/markdown-it/markdown-it/compare/8.2.1...8.2.2
[8.2.1]: https://github.com/markdown-it/markdown-it/compare/8.2.0...8.2.1
[8.2.0]: https://github.com/markdown-it/markdown-it/compare/8.1.0...8.2.0
[8.1.0]: https://github.com/markdown-it/markdown-it/compare/8.0.1...8.1.0
[8.0.1]: https://github.com/markdown-it/markdown-it/compare/8.0.0...8.0.1
[8.0.0]: https://github.com/markdown-it/markdown-it/compare/7.0.1...8.0.0
[7.0.1]: https://github.com/markdown-it/markdown-it/compare/7.0.0...7.0.1
[7.0.0]: https://github.com/markdown-it/markdown-it/compare/6.1.1...7.0.0
[6.1.1]: https://github.com/markdown-it/markdown-it/compare/6.1.0...6.1.1
[6.1.0]: https://github.com/markdown-it/markdown-it/compare/6.0.5...6.1.0
[6.0.5]: https://github.com/markdown-it/markdown-it/compare/6.0.4...6.0.5
[6.0.4]: https://github.com/markdown-it/markdown-it/compare/6.0.3...6.0.4
[6.0.3]: https://github.com/markdown-it/markdown-it/compare/6.0.2...6.0.3
[6.0.2]: https://github.com/markdown-it/markdown-it/compare/6.0.1...6.0.2
[6.0.1]: https://github.com/markdown-it/markdown-it/compare/6.0.0...6.0.1
[6.0.0]: https://github.com/markdown-it/markdown-it/compare/5.1.0...6.0.0
[5.1.0]: https://github.com/markdown-it/markdown-it/compare/5.0.3...5.1.0
[5.0.3]: https://github.com/markdown-it/markdown-it/compare/5.0.2...5.0.3
[5.0.2]: https://github.com/markdown-it/markdown-it/compare/5.0.1...5.0.2
[5.0.1]: https://github.com/markdown-it/markdown-it/compare/5.0.0...5.0.1
[5.0.0]: https://github.com/markdown-it/markdown-it/compare/4.4.0...5.0.0
[4.4.0]: https://github.com/markdown-it/markdown-it/compare/4.3.1...4.4.0
[4.3.1]: https://github.com/markdown-it/markdown-it/compare/4.3.0...4.3.1
[4.3.0]: https://github.com/markdown-it/markdown-it/compare/4.2.2...4.3.0
[4.2.2]: https://github.com/markdown-it/markdown-it/compare/4.2.1...4.2.2
[4.2.1]: https://github.com/markdown-it/markdown-it/compare/4.2.0...4.2.1
[4.2.0]: https://github.com/markdown-it/markdown-it/compare/4.1.2...4.2.0
[4.1.2]: https://github.com/markdown-it/markdown-it/compare/4.1.1...4.1.2
[4.1.1]: https://github.com/markdown-it/markdown-it/compare/4.1.0...4.1.1
[4.1.0]: https://github.com/markdown-it/markdown-it/compare/4.0.3...4.1.0
[4.0.3]: https://github.com/markdown-it/markdown-it/compare/4.0.2...4.0.3
[4.0.2]: https://github.com/markdown-it/markdown-it/compare/4.0.1...4.0.2
[4.0.1]: https://github.com/markdown-it/markdown-it/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/markdown-it/markdown-it/compare/3.1.0...4.0.0
[3.1.0]: https://github.com/markdown-it/markdown-it/compare/3.0.7...3.1.0
[3.0.7]: https://github.com/markdown-it/markdown-it/compare/3.0.6...3.0.7
[3.0.6]: https://github.com/markdown-it/markdown-it/compare/3.0.5...3.0.6
[3.0.5]: https://github.com/markdown-it/markdown-it/compare/3.0.4...3.0.5
[3.0.4]: https://github.com/markdown-it/markdown-it/compare/3.0.3...3.0.4
[3.0.3]: https://github.com/markdown-it/markdown-it/compare/3.0.2...3.0.3
[3.0.2]: https://github.com/markdown-it/markdown-it/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/markdown-it/markdown-it/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/markdown-it/markdown-it/compare/2.2.1...3.0.0
[2.2.1]: https://github.com/markdown-it/markdown-it/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/markdown-it/markdown-it/compare/2.1.3...2.2.0
[2.1.3]: https://github.com/markdown-it/markdown-it/compare/2.1.2...2.1.3
[2.1.2]: https://github.com/markdown-it/markdown-it/compare/2.1.1...2.1.2
[2.1.1]: https://github.com/markdown-it/markdown-it/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/markdown-it/markdown-it/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/markdown-it/markdown-it/releases/tag/2.0.0
