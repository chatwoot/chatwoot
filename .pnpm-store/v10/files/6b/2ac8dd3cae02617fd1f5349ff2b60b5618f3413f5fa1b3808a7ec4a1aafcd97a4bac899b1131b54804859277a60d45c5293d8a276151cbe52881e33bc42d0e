## 1.13.0 (2024-05-20)

### Bug fixes

Fix the type of `MarkdownParser.parse` to be non-nullable. Add a strict option to MarkdownSerializer

### New features

The new `strict` option to `MarkdownSerializer` makes it possible to make the serializer ignore node and mark types it doesn't know.

## 1.12.0 (2023-12-11)

### Bug fixes

Block-level markup inside a heading is no longer escaped by the serializer.

Do not backslash-escape a `+` at the start of line when it isn't followed by a space. Upgrade to markdown-it 14

### New features

`MarkdownSerializerState.renderInline` now takes a parameter that controls whether block-level markup should be escaped.

Upgrade to markdown-it version 14, which provides ES modules.

## 1.11.2 (2023-08-04)

### Bug fixes

Fix some unnecessary escapes for period characters in Markdown serialization.

Only escape `#` signs if they would otherwise create a heading. Add a test for headings in list items

Fix a bug in `MarkdownSerializer` that broken expelling of whitespace from marks when the mark spanned multiple nodes.

## 1.11.1 (2023-06-30)

### Bug fixes

Allow any blocks as first child of list items to align with what Markdown itself does.

Add parse rules that clear `strong` and `em` marks when inline CSS resets it.

## 1.11.0 (2023-05-17)

### Bug fixes

Make sure blank lines at the end of code blocks are properly serialized.

Convert soft breaks (single newlines) in Markdown to spaces, rather than newlines in the ProseMirror document, because newlines tend to behave awkwardly in the editor.

Fix a bug that cause the object passed as configuration to `MarkdownSerializer` to be mutated. Add release note

Include CommonJS type declarations in the package to please new TypeScript resolution settings.

### New features

A new option to `MarkdownSerializer` allows client code to configure which node type should be treated as hard breaks during mark serialization. Remove the extra left bracket

## 1.10.1 (2022-10-28)

### Bug fixes

Don't treat the empty string the same as `null` in `wrapBlock`'s `firstDelim` argument. Check content of code blocks for any sequence of backticks

Use longer sequences of backticks when serializing a code block that contains three or more backticks in a row.

## 1.10.0 (2022-10-05)

### New features

You can now pass an optional markdown-it environment object to .

## 1.9.4 (2022-08-19)

### Bug fixes

Don't escape colon characters at the start of a line.

Escape parentheses in images and links.

Allow links to wrap emphasis markers when serializing Markdown.

## 1.9.3 (2022-07-05)

### Bug fixes

Make sure '\!' characters in front of links are escaped.

## 1.9.2 (2022-07-04)

### Bug fixes

Don't escape characters in autolinks.

Fix a bug that caused the serializer to not escape start-of-line markup when inside a list.

## 1.9.1 (2022-06-02)

### Bug fixes

Fix a bug where inline nodes with content would reset the marks in their parent node during Markdown parsing.

## 1.9.0 (2022-05-30)

### New features

Include TypeScript type declarations.

## 1.8.0 (2022-03-14)

### New features

`MarkdownSerializer` now takes an `escapeExtraCharacters` option that can be used to control backslash-escaping behavior. Fix types for new option

## 1.7.1 (2022-02-16)

### Bug fixes

Avoid escaping underscores surrounded by word characters.

## 1.7.0 (2022-01-06)

### New features

Upgrade markdown-it to version 12.

## 1.6.2 (2022-01-04)

### Bug fixes

Fix a bug where URL text in links and images was overzealously escaped.

## 1.6.1 (2021-12-16)

### Bug fixes

Fix a bug where `MarkdownParser.parse` could return null when the parsed content doesn't fit the schema.

Make sure underscores are escaped when serializing to Markdown.

## 1.6.0 (2021-09-21)

### New features

`MarkdownParser.tokenizer` is now public, for easier creation of parsers that base on other parsers.

## 1.5.2 (2021-09-03)

### Bug fixes

Serializing to Markdown now properly escapes '>' characters at the start of the line.

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
