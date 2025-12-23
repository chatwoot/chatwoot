# Change Log
All notable changes to this project will be documented in this file.

## 2.1.1 - October 2021
- Fixes unintentional newline characters within lists with paragraphs, thanks @diogoosorio, see #93
- Lets \n to be present in <pre> tag. solves #77 #78, thanks @shivabhusal

## 2.1.0 - May 2020
- Add support for `figure` tags, see #86, thanks @anshul78

## 2.0.0 - March 2020
- BREAKING: Dropped support for ruby 1.9.3
- Add support for `details` and `summary` tags, see #85

## 1.4.0 – January 2020
- BREAKING: jump links will no longer be ignored but treated as links, see #82

## 1.3.0 - September 2019
- Add support for `s` HTML tag, thanks @fauno

## 1.2.0 - August 2019
- Handle windows `\r\n` within text blocks, thanks for reporting @krisdigital
- Handle paragraphs in `li` tags, thanks @gstamp

## 1.1.0 - April 2018
- Support Jruby, thanks @grddev (#71)
- Bypass `<tfoot>` tags, thanks @mu-is-too-short (#70)

## 1.0.5 - February 2018
- Fix newline handling within pre tags, thanks @niallcolfer (#69)

## 1.0.4 - November 2017
- Make blockquote behave as true block, thanks for reporting @kanedo (#67)

## 1.0.3 - Apr 2016
### Changes
- Use tag_border option while cleaning up, thanks @AlexanderPruss (#66)

## 1.0.2 - Apr 2016
### Changes
- Handle edge case: exclamation mark before links, thanks @Easy-D (#57)

## 1.0.1 - Jan 2016
### Changes
- Prevent double escaping of * and _, thanks @craig-day (#61)

## 1.0.0 - Nov 2015
### Changes
- BREAKING: Parsing was significantly improved, thanks @craig-day (#60)
  Please update your custom converters to accept and use the state hash, for
  examples look into exisiting standard converters.
- Use OptionParser for command line options, thanks @grmartin (#55)
- Tag border behavior is now configurable with the `tag_border` option, thanks @faheemmughal (#59)
- Preserve &gt; and &lt; from original markup, thanks @willglynn (#58)

## 0.8.2 - May 2015
### Changes
- Don't add whitespaces in links and images if they contain underscores

## 0.8.1 - April 2015
### Changes
- Don't add newlines after nested lists

## 0.8.0 - April 2015
### Added
- `article` tag is now supported and treated like a div

### Changed
- Special characters are treated correctly inside of backticks, see (#47)

## 0.7.0 - February 2015
### Added
- pre-tags support syntax github and confluence syntax highlighting now

## 0.6.1 - January 2015
### Changed
- Setting config options in block style will last for all following `convert` calls.
- Inline config options are only applied to this particular operation

### Removed
- `config.reset` is removed

## 0.6.0 - September 2014
### Added
- Ignore `col` and `colgroup` tags
- Bypass `thead` and `tbody` tags to show the tables correctly

### Changed
- Eliminate ruby warnings on load (thx @vsipuli)
- Treat newlines within text nodes as space
- Remove whitespace between inline tags and punctuation characters


## 0.5.1 - April 2014
### Added
- Adds support for ruby versions 1.9.3 back in
- More options for handling of unknown tags

### Changed
- Bugfixes in `li` indentation behavior


## 0.5.0 - March 2014
**There were some breaking changes, please make sure you don't miss them:**

1. Only ruby versions 2.0.0 or above are supported
2. There is no `Mapper` class any more. Just use `ReverseMarkdown.convert(input, options)`
3. Config option `github_style_code_blocks` changed its name to `github_flavored`

Please open an issue and let me know about it if you have any trouble with the new version.
