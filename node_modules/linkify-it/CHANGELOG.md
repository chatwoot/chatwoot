2.2.0 / 2019-07-12
------------------

- Improved quoted email detect (disable `"` at email start), #72.
- Fix some google links (allow more consecutive `.`), #66.


2.1.0 / 2018-11-27
------------------

- Allow `--` (and more dashes) in domain names, #63.


2.0.3 / 2016-12-09
------------------

- Process `｜` (asian vertical pipe 0xFF5C) as valid text separator.


2.0.2 / 2016-10-15
------------------

- Allow dashes in local domains, #43.


2.0.1 / 2016-09-28
------------------

- Restrict user:pass@... content - prohibit "()[]" chars in auth, #41.


2.0.0 / 2016-06-22
------------------

- `---` no longer terminates link. Use option `{ '---': true }` to return old
  behaviour.
- `.onCompile()` hook to modify base regexp constants.
- Allow `foo'-bar` in path


1.2.4 / 2016-06-03
------------------

- Consider `<` & `>` as invalid in links.
- Support links in lt/gt braces: `<user@domain.com>`, `<http://example.com>`.


1.2.3 / 2016-05-31
------------------

- Allow digits in local domains, #36.
- Restrict user/pass (prohibit [@/] chars) to avoid wrong domain fetch.
- More restrictions for protocol-transparent links. Don't allow single-level
  (local) domains, except '//localhost', #19.


1.2.2 / 2016-05-30
------------------

- Security fix: due problem in `Any` class regexp from old `unicode-7.0.0`
  package (used in `uc-micro`), hang happend with astral char patterns like
  `😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡 .com` if fuzzy
  options used. New installs will use fixed `uc-micro` automatically.
  Old installs need to be updated. #36.
- Unicode rules updated to 8.+ version.


1.2.1 / 2016-04-29
------------------

- Fix detect email after opening parenthesis: `(my@email.com)`, #32.


1.2.0 / 2015-06-29
------------------

- Allow dash at the end of url, thanks to @Mumakil.


1.1.1 / 2015-06-09
------------------

- Allow ".." in link paths.


1.1.0 / 2015-04-21
------------------

- Added options to control fuzzy links recognition (`fuzzyLink: true`,
  `fuzzyEmail: true`, `fuzzyIP: false`).
- Disabled IP-links without schema prefix by default.


1.0.1 / 2015-04-19
------------------

- More strict default 2-characters tlds handle in fuzzy links, to avoid
  false positives for `node.js`, `io.js` and so on.


1.0.0 / 2015-03-25
------------------

- Version bump to 1.0.0 for semver.
- Removed `Cf` class from whitespace & punctuation sets (#10).
- API change. Exported regex names renamed to reflect changes. Update your
  custom rules if needed:
  - `src_ZPCcCf` -> `src_ZPCc`
  - `src_ZCcCf` -> `src_ZCc`


0.1.5 / 2015-03-13
------------------

- Fixed special chars handling (line breaks).
- Fixed demo permalink encode/decode.


0.1.4 / 2015-03-12
------------------

- Allow `..` and `...` inside of link paths (#9). Useful for github links with
  commit ranges.
- Added `.pretest()` method for speed optimizations.
- Autogenerate demo sample from fixtures.


0.1.3 / 2015-03-11
------------------

- Maintenance release. Deps update.


0.1.2 / 2015-02-26
------------------

- Fixed blockquoted links (some symbols exclusions), thanks to @MayhemYDG.
- Fixed demo permalinks, thanks to @MayhemYDG.


0.1.1 / 2015-02-22
------------------

- Moved unicode data to external package.
- Demo permalink improvements.
- Docs update.


0.1.0 / 2015-02-12
------------------

- First release.
