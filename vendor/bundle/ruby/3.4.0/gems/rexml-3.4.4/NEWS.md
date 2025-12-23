# News

## 3.4.4 - 2025-09-10 {#version-3-4-4}

### Improvement

  * Accept `REXML::Document.new("")` for backward compatibility
    * GH-296
    * GH-295
    * Patch by NAITOH Jun
    * Reported by Joe Rafaniello

### Thanks

  * NAITOH Jun

  * Joe Rafaniello

## 3.4.3 - 2025-09-07 {#version-3-4-3}

### Improvement

  * Reject no root element XML as an invalid XML
    * GH-289
    * GH-291
    * Patch by NAITOH Jun
    * Reported by Sutou Kouhei

### Fixes

  * Fixed an issue with `IOSource#read_until` when reaching the end of a file
    * GH-287
    * GH-288
    * Patch by NAITOH Jun
    * Reported by Jason Thomas

### Thanks

  * NAITOH Jun

  * Sutou Kouhei

  * Jason Thomas

## 3.4.2 - 2025-08-26 {#version-3-4-2}

### Improvement

  * Improved performance.
    * GH-244
    * GH-245
    * GH-246
    * GH-249
    * GH-256
    * Patch by NAITOH Jun

  * Raise appropriate exception when failing to match start tag in DOCTYPE
    * GH-247
    * Patch by NAITOH Jun

  * Deprecate accepting array as an element in XPath.match, first and each
    * GH-252
    * Patch by tomoya ishida

  * Don't call needless encoding_updated
    * GH-259
    * Patch by Sutou Kouhei

  * Reuse XPath::match
    * GH-263
    * Patch by pboling

  * Cache redundant calls for doctype
    * GH-264
    * Patch by pboling

  * Use Safe Navigation (&.) from Ruby 2.3
    * GH-265
    * Patch by pboling

  * Remove redundant return statements
    * GH-266
    * Patch by pboling

  * Added XML declaration check & Source#skip_spaces method
    * GH-282
    * Patch by NAITOH Jun
    * Reported by Sofi Aberegg

### Fixes

  * Fix docs typo
    * GH-248
    * Patch by James Coleman

  * Fix reverse sort in xpath_parser
    * GH-251
    * Patch by tomoya ishida

  * Fix duplicate responses in XPath following, following-sibling, preceding, preceding-sibling
    * GH-255
    * Patch by NAITOH Jun

  * Fix wrong Encoding resolution
    * GH-258
    * Patch by Sutou Kouhei

  * Handle nil when parsing fragment
    * GH-267
    * GH-268
    * Patch by pboling

  * [Documentation] Use # to reference instance methods
    * GH-269
    * GH-270
    * Patch by pboling

  * Fix & Deprecate REXML::Text#text_indent
    * GH-273
    * GH-275
    * Patch by pboling

  * remove bundler from dev deps
    * GH-276
    * GH-277
    * Patch by pboling

  * remove ostruct from dev deps
    * GH-280
    * GH-281
    * Patch by pboling

### Thanks

  * NAITOH Jun

  * tomoya ishida

  * James Coleman

  * pboling

  * Sutou Kouhei

  * Sofi Aberegg

## 3.4.1 - 2025-02-16 {#version-3-4-1}

### Improvement

  * Improved performance.
    * GH-226
    * GH-227
    * GH-237
    * Patch by NAITOH Jun

### Fixes

  * Fix serialization of ATTLIST is incorrect
    * GH-233
    * GH-234
    * Patch by OlofKalufs
    * Reported by OlofKalufs

### Thanks

  * NAITOH Jun

  * OlofKalufs

## 3.4.0 - 2024-12-15 {#version-3-4-0}

### Improvement

  * Improved performance.
    * GH-216
    * Patch by NAITOH Jun

  * JRuby: Improved parse performance.
    * GH-219
    * Patch by João Duarte

  * Added support for reusing pull parser.
    * GH-214
    * GH-220
    * Patch by Dmitry Pogrebnoy

  * Improved error handling when source is `IO`.
    * GH-221
    * Patch by NAITOH Jun

### Thanks

  * NAITOH Jun

  * João Duarte

  * Dmitry Pogrebnoy

## 3.3.9 - 2024-10-24 {#version-3-3-9}

### Improvements

  * Improved performance.
    * GH-210
    * Patch by NAITOH Jun.

### Fixes

  * Fixed a parse bug for text only invalid XML.
    * GH-215
    * Patch by NAITOH Jun.

  * Fixed a parse bug that `&#0x...;` is accepted as a character
    reference.

### Thanks

  * NAITOH Jun

## 3.3.8 - 2024-09-29 {#version-3-3-8}

### Improvements

  * SAX2: Improve parse performance.
    * GH-207
    * Patch by NAITOH Jun.

### Fixes

  * Fixed a bug that unexpected attribute namespace conflict error for
    the predefined "xml" namespace is reported.
    * GH-208
    * Patch by KITAITI Makoto

### Thanks

  * NAITOH Jun

  * KITAITI Makoto

## 3.3.7 - 2024-09-04 {#version-3-3-7}

### Improvements

  * Added local entity expansion limit methods
    * GH-192
    * GH-202
    * Reported by takuya kodama.
    * Patch by NAITOH Jun.

  * Removed explicit strscan dependency
    * GH-204
    * Patch by Bo Anderson.

### Thanks

  * takuya kodama

  * NAITOH Jun

  * Bo Anderson

## 3.3.6 - 2024-08-22 {#version-3-3-6}

### Improvements

  * Removed duplicated entity expansions for performance.
    * GH-194
    * Patch by Viktor Ivarsson.

  * Improved namespace conflicted attribute check performance. It was
    too slow for deep elements.
    * Reported by l33thaxor.

### Fixes

  * Fixed a bug that default entity expansions are counted for
    security check. Default entity expansions should not be counted
    because they don't have a security risk.
    * GH-198
    * GH-199
    * Patch Viktor Ivarsson

  * Fixed a parser bug that parameter entity references in internal
    subsets are expanded. It's not allowed in the XML specification.
    * GH-191
    * Patch by NAITOH Jun.

  * Fixed a stream parser bug that user-defined entity references in
    text aren't expanded.
    * GH-200
    * Patch by NAITOH Jun.

### Thanks

  * Viktor Ivarsson

  * NAITOH Jun

  * l33thaxor

## 3.3.5 - 2024-08-12 {#version-3-3-5}

### Fixes

  * Fixed a bug that `REXML::Security.entity_expansion_text_limit`
    check has wrong text size calculation in SAX and pull parsers.
    * GH-193
    * GH-195
    * Reported by Viktor Ivarsson.
    * Patch by NAITOH Jun.

### Thanks

  * Viktor Ivarsson

  * NAITOH Jun

## 3.3.4 - 2024-08-01 {#version-3-3-4}

### Fixes

  * Fixed a bug that `REXML::Security` isn't defined when
    `REXML::Parsers::StreamParser` is used and
    `rexml/parsers/streamparser` is only required.
    * GH-189
    * Patch by takuya kodama.

### Thanks

  * takuya kodama

## 3.3.3 - 2024-08-01 {#version-3-3-3}

### Improvements

  * Added support for detecting invalid XML that has unsupported
    content before root element
    * GH-184
    * Patch by NAITOH Jun.

  * Added support for `REXML::Security.entity_expansion_limit=` and
    `REXML::Security.entity_expansion_text_limit=` in SAX2 and pull
    parsers
    * GH-187
    * Patch by NAITOH Jun.

  * Added more tests for invalid XMLs.
    * GH-183
    * Patch by Watson.

  * Added more performance tests.
    * Patch by Watson.

  * Improved parse performance.
    * GH-186
    * Patch by tomoya ishida.

### Thanks

  * NAITOH Jun

  * Watson

  * tomoya ishida

## 3.3.2 - 2024-07-16 {#version-3-3-2}

### Improvements

  * Improved parse performance.
    * GH-160
    * Patch by NAITOH Jun.

  * Improved parse performance.
    * GH-169
    * GH-170
    * GH-171
    * GH-172
    * GH-173
    * GH-174
    * GH-175
    * GH-176
    * GH-177
    * Patch by Watson.

  * Added support for raising a parse exception when an XML has extra
    content after the root element.
    * GH-161
    * Patch by NAITOH Jun.

  * Added support for raising a parse exception when an XML
    declaration exists in wrong position.
    * GH-162
    * Patch by NAITOH Jun.

  * Removed needless a space after XML declaration in pretty print mode.
    * GH-164
    * Patch by NAITOH Jun.

  * Stopped to emit `:text` event after the root element.
    * GH-167
    * Patch by NAITOH Jun.

### Fixes

  * Fixed a bug that SAX2 parser doesn't expand predefined entities for
    `characters` callback.
    * GH-168
    * Patch by NAITOH Jun.

### Thanks

  * NAITOH Jun

  * Watson

## 3.3.1 - 2024-06-25 {#version-3-3-1}

### Improvements

  * Added support for detecting malformed top-level comments.
    * GH-145
    * Patch by Hiroya Fujinami.

  * Improved `REXML::Element#attribute` performance.
    * GH-146
    * Patch by Hiroya Fujinami.

  * Added support for detecting malformed `<!-->` comments.
    * GH-147
    * Patch by Hiroya Fujinami.

  * Added support for detecting unclosed `DOCTYPE`.
    * GH-152
    * Patch by Hiroya Fujinami.

  * Added `changlog_uri` metadata to gemspec.
    * GH-156
    * Patch by fynsta.

  * Improved parse performance.
    * GH-157
    * GH-158
    * Patch by NAITOH Jun.

### Fixes

  * Fixed a bug that large XML can't be parsed.
    * GH-154
    * Patch by NAITOH Jun.

  * Fixed a bug that private constants are visible.
    * GH-155
    * Patch by NAITOH Jun.

### Thanks

  * Hiroya Fujinami

  * NAITOH Jun

  * fynsta

## 3.3.0 - 2024-06-11 {#version-3-3-0}

### Improvements

  * Added support for strscan 0.7.0 installed with Ruby 2.6.
    * GH-142
    * Reported by Fernando Trigoso.

### Thanks

  * Fernando Trigoso

## 3.2.9 - 2024-06-09 {#version-3-2-9}

### Improvements

  * Added support for old strscan.
    * GH-132
    * Reported by Adam.

  * Improved attribute value parse performance.
    * GH-135
    * Patch by NAITOH Jun.

  * Improved `REXML::Node#each_recursive` performance.
    * GH-134
    * GH-139
    * Patch by Hiroya Fujinami.

  * Improved text parse performance.
    * Reported by mprogrammer.

### Thanks

  * Adam
  * NAITOH Jun
  * Hiroya Fujinami
  * mprogrammer

## 3.2.8 - 2024-05-16 {#version-3-2-8}

### Fixes

  * Suppressed a warning

## 3.2.7 - 2024-05-16 {#version-3-2-7}

### Improvements

  * Improve parse performance by using `StringScanner`.

    * GH-106
    * GH-107
    * GH-108
    * GH-109
    * GH-112
    * GH-113
    * GH-114
    * GH-115
    * GH-116
    * GH-117
    * GH-118
    * GH-119
    * GH-121

    * Patch by NAITOH Jun.

  * Improved parse performance when an attribute has many `>`s.

    * GH-126

### Fixes

  * XPath: Fixed a bug of `normalize_space(array)`.

    * GH-110
    * GH-111

    * Patch by flatisland.

  * XPath: Fixed a bug that wrong position is used with nested path.

    * GH-110
    * GH-122

    * Reported by jcavalieri.
    * Patch by NAITOH Jun.

  * Fixed a bug that an exception message can't be generated for
    invalid encoding XML.

    * GH-29
    * GH-123

    * Reported by DuKewu.
    * Patch by NAITOH Jun.

### Thanks

  * NAITOH Jun
  * flatisland
  * jcavalieri
  * DuKewu

## 3.2.6 - 2023-07-27 {#version-3-2-6}

### Improvements

  * Required Ruby 2.5 or later explicitly.
    [GH-69][gh-69]
    [Patch by Ivo Anjo]

  * Added documentation for maintenance cycle.
    [GH-71][gh-71]
    [Patch by Ivo Anjo]

  * Added tutorial.
    [GH-77][gh-77]
    [GH-78][gh-78]
    [Patch by Burdette Lamar]

  * Improved performance and memory usage.
    [GH-94][gh-94]
    [Patch by fatkodima]

  * `REXML::Parsers::XPathParser#abbreviate`: Added support for
    function arguments.
    [GH-95][gh-95]
    [Reported by pulver]

  * `REXML::Parsers::XPathParser#abbreviate`: Added support for string
    literal that contains double-quote.
    [GH-96][gh-96]
    [Patch by pulver]

  * `REXML::Parsers::XPathParser#abbreviate`: Added missing `/` to
    `:descendant_or_self/:self/:parent`.
    [GH-97][gh-97]
    [Reported by pulver]

  * `REXML::Parsers::XPathParser#abbreviate`: Added support for more patterns.
    [GH-97][gh-97]
    [Reported by pulver]

### Fixes

  * Fixed a typo in NEWS.
    [GH-72][gh-72]
    [Patch by Spencer Goodman]

  * Fixed a typo in NEWS.
    [GH-75][gh-75]
    [Patch by Andrew Bromwich]

  * Fixed documents.
    [GH-87][gh-87]
    [Patch by Alexander Ilyin]

  * Fixed a bug that `Attriute` convert `'` and `&apos;` even when
    `attribute_quote: :quote` is used.
    [GH-92][gh-92]
    [Reported by Edouard Brière]

  * Fixed links in tutorial.
    [GH-99][gh-99]
    [Patch by gemmaro]


### Thanks

  * Ivo Anjo

  * Spencer Goodman

  * Andrew Bromwich

  * Burdette Lamar

  * Alexander Ilyin

  * Edouard Brière

  * fatkodima

  * pulver

  * gemmaro

[gh-69]:https://github.com/ruby/rexml/issues/69
[gh-71]:https://github.com/ruby/rexml/issues/71
[gh-72]:https://github.com/ruby/rexml/issues/72
[gh-75]:https://github.com/ruby/rexml/issues/75
[gh-77]:https://github.com/ruby/rexml/issues/77
[gh-87]:https://github.com/ruby/rexml/issues/87
[gh-92]:https://github.com/ruby/rexml/issues/92
[gh-94]:https://github.com/ruby/rexml/issues/94
[gh-95]:https://github.com/ruby/rexml/issues/95
[gh-96]:https://github.com/ruby/rexml/issues/96
[gh-97]:https://github.com/ruby/rexml/issues/97
[gh-98]:https://github.com/ruby/rexml/issues/98
[gh-99]:https://github.com/ruby/rexml/issues/99

## 3.2.5 - 2021-04-05 {#version-3-2-5}

### Improvements

  * Add more validations to XPath parser.

  * `require "rexml/document"` by default.
    [GitHub#36][Patch by Koichi ITO]

  * Don't add `#dclone` method to core classes globally.
    [GitHub#37][Patch by Akira Matsuda]

  * Add more documentations.
    [Patch by Burdette Lamar]

  * Added `REXML::Elements#parent`.
    [GitHub#52][Patch by Burdette Lamar]

### Fixes

  * Fixed a bug that `REXML::DocType#clone` doesn't copy external ID
    information.

  * Fixed round-trip vulnerability bugs.
    See also: https://www.ruby-lang.org/en/news/2021/04/05/xml-round-trip-vulnerability-in-rexml-cve-2021-28965/
    [HackerOne#1104077][CVE-2021-28965][Reported by Juho Nurminen]

### Thanks

  * Koichi ITO

  * Akira Matsuda

  * Burdette Lamar

  * Juho Nurminen

## 3.2.4 - 2020-01-31 {#version-3-2-4}

### Improvements

  * Don't use `taint` with Ruby 2.7 or later.
    [GitHub#21][Patch by Jeremy Evans]

### Fixes

  * Fixed a `elsif` typo.
    [GitHub#22][Patch by Nobuyoshi Nakada]

### Thanks

  * Jeremy Evans

  * Nobuyoshi Nakada

## 3.2.3 - 2019-10-12 {#version-3-2-3}

### Fixes

  * Fixed a bug that `REXML::XMLDecl#close` doesn't copy `@writethis`.
    [GitHub#20][Patch by hirura]

### Thanks

  * hirura

## 3.2.2 - 2019-06-03 {#version-3-2-2}

### Fixes

  * xpath: Fixed a bug for equality and relational expressions.
    [GitHub#17][Reported by Mirko Budszuhn]

  * xpath: Fixed `boolean()` implementation.

  * xpath: Fixed `local_name()` with nonexistent node.

  * xpath: Fixed `number()` implementation with node set.
    [GitHub#18][Reported by Mirko Budszuhn]

### Thanks

  * Mirko Budszuhn

## 3.2.1 - 2019-05-04 {#version-3-2-1}

### Improvements

  * Improved error message.
    [GitHub#12][Patch by FUJI Goro]

  * Improved error message.
    [GitHub#16][Patch by ujihisa]

  * Improved documentation markup.
    [GitHub#14][Patch by Alyssa Ross]

### Fixes

  * Fixed a bug that `nil` variable value raises an unexpected exception.
    [GitHub#13][Patch by Alyssa Ross]

### Thanks

  * FUJI Goro

  * Alyssa Ross

  * ujihisa

## 3.2.0 - 2019-01-01 {#version-3-2-0}

### Fixes

  * Fixed a bug that no namespace attribute isn't matched with prefix.

    [ruby-list:50731][Reported by Yasuhiro KIMURA]

  * Fixed a bug that the default namespace is applied to attribute names.

    NOTE: It's a backward incompatible change. If your program has any
    problem with this change, please report it. We may revert this fix.

    * `REXML::Attribute#prefix` returns `""` for no namespace attribute.

    * `REXML::Attribute#namespace` returns `""` for no namespace attribute.

### Thanks

  * Yasuhiro KIMURA

## 3.1.9 - 2018-12-20 {#version-3-1-9}

### Improvements

  * Improved backward compatibility.

    Restored `REXML::Parsers::BaseParser::UNQME_STR` because it's used
    by kramdown.

## 3.1.8 - 2018-12-20 {#version-3-1-8}

### Improvements

  * Added support for customizing quote character in prologue.
    [GitHub#8][Bug #9367][Reported by Takashi Oguma]

    * You can use `"` as quote character by specifying `:quote` to
      `REXML::Document#context[:prologue_quote]`.

    * You can use `'` as quote character by specifying `:apostrophe`
      to `REXML::Document#context[:prologue_quote]`.

  * Added processing instruction target check. The target must not nil.
    [GitHub#7][Reported by Ariel Zelivansky]

  * Added name check for element and attribute.
    [GitHub#7][Reported by Ariel Zelivansky]

  * Stopped to use `Exception`.
    [GitHub#9][Patch by Jean Boussier]

### Fixes

  * Fixed a bug that `REXML::Text#clone` escapes value twice.
    [ruby-dev:50626][Bug #15058][Reported by Ryosuke Nanba]

### Thanks

  * Takashi Oguma

  * Ariel Zelivansky

  * Jean Boussier

  * Ryosuke Nanba
