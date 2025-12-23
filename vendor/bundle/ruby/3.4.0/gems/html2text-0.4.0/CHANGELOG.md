# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2024-06-08
### Added
- Switch from Travis to Github Actions for Build and Test
- Add rubocop for linting and cleanup existing violations ([#36](https://github.com/soundasleep/html2text_ruby/pull/36))

### Changed
- Add support for Ruby 3.x, removed support for Ruby < 3.0 since it is EOL
- Allow subclassing of `Html2Text` to override the default behaviour ([#30](https://github.com/soundasleep/html2text_ruby/pull/30))

### Fixed
- Loosen nokogiri dependency to allow for nokogiri < 2.0 ([#17](https://github.com/soundasleep/html2text_ruby/pull/17))
- Fix `NoMethodError` when parsing nodes with no name ([#15](https://github.com/soundasleep/html2text_ruby/pull/15))

## [0.3.1] - 2019-06-12
### Security
- Bumped nokogiri requirement to ~> 1.10.3, resolving [CVE-2019-11068](https://nvd.nist.gov/vuln/detail/CVE-2019-11068)
  ([#8](https://github.com/soundasleep/html2text_ruby/issues/8))

## [0.3.0] - 2019-02-15
### Added
- Zero-width non-joiners are now stripped ([#5](https://github.com/soundasleep/html2text_ruby/pull/5))
- Support both UTF-8 and Windows-1252 encoded files
- Support converting `<pre>` blocks, including whitespace within these blocks
- MS Office (MsoNormal) documents are now rendered closer to actual render output
  - Note this assumes that the input MS Office document has standard `MsoNormal` CSS.
    This component is _not_ designed to try and interpret CSS within an HTML document.

### Changed
- Behaviour with multiple and nested `<p>`, `<div>` tags has been improved to be more in line with
  actual browser render behaviour (see test suite)

### Fixed
- Update nokogiri dependency to 1.8.5

## [0.2.1] - 2017-09-27
### Fixed
- Convert non-string input into strings ([#3](https://github.com/soundasleep/html2text_ruby/pull/3))

[Unreleased]: https://github.com/soundasleep/html2text_ruby/compare/0.3.1...HEAD
[0.3.1]: https://github.com/soundasleep/html2text_ruby/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/soundasleep/html2text_ruby/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/soundasleep/html2text_ruby/compare/0.2.1...0.2.1
