## 1.5.1 (2021-01-06)

### Bug fixes

The Markdown parser will now correctly set the `tight` attribute on list nodes.

## 1.5.0 (2020-07-17)

### New features

Markdown parse specs can now be specified as `noCloseToken`, which will cause the parser to treat them as a single token, rather than a pair of `_open`/`_close` tokens.

## 1.4.5 (2020-05-14)

### Bug fixes

Don't allow hard_break nodes in headings.

## 1.4.4 (2019-12-19)

### Bug fixes

Fix issue that broke parsing ordered lists with a starting number other than 1.

## 1.4.3 (2019-12-17)

### Bug fixes

Don't use short-hand angle bracket syntax when outputting self-linking URLs that are relative.

## 1.4.2 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.4.1 (2019-11-19)

### Bug fixes

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.4.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.3.2 (2019-10-30)

### Bug fixes

Code blocks in the schema no longer allow marks inside them.

Code blocks are now parsed with `preserveWhiteSpace: full`, preventing removal of newline characters.

## 1.3.1 (2019-06-08)

### Bug fixes

Fix a bug that could occur when parsing multiple adjacent pieces of text with the same style.

## 1.3.0 (2019-01-22)

### Bug fixes

Inline code containing backticks is now serialized wrapped in the appropriate amount of backticks.

### New features

The serializer now serializes links whose target is the same as their text content using \< \> syntax.

Mark opening and close string callbacks now get passed the mark's context (parent fragment and index).

## 1.2.2 (2018-11-22)

### Bug fixes

Hard breaks at the end of an emphasized or strong mark are no longer serialized to invalid Markdown text.

## 1.2.1 (2018-10-19)

### Bug fixes

Fixes a bug where inline mark delimiters were serialized incorrectly (the closing and opening marks were swapped, which was only noticeable when they are different).

## 1.2.0 (2018-10-08)

### Bug fixes

Fixes an issue where the Markdown serializer would escape special characters in inline code.

### New features

Upgrade the markdown-it dependency to version 8.

## 1.1.1 (2018-07-08)

### Bug fixes

Fix bug that caused superfluous backslashes to be inserted at the start of some lines when serializing to Markdown.

## 1.1.0 (2018-06-20)

### New features

You can now override the handling of softbreak tokens in a custom handler.

## 1.0.4 (2018-04-17)

### Bug fixes

Fix crash when serializing marks with line breaks inside of them.

## 1.0.3 (2018-01-10)

### Bug fixes

Fix dependency version range for prosemirror-model.

## 1.0.2 (2017-12-07)

### Bug fixes

Code blocks are always wrapped in triple backticks when serializing, to avoid parsing corner cases around indented code blocks.

## 1.0.1 (2017-11-05)

### Bug fixes

Link marks are now non-inclusive (typing after them produces non-linked text).

## 1.0.0 (2017-10-13)

First stable release.
