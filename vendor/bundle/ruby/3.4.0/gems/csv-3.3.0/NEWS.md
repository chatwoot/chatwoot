# News

## 3.3.0 - 2024-03-22

### Fixes

  * Fixed a regression parse bug in 3.2.9 that parsing with
    `:skip_lines` may cause wrong result.

## 3.2.9 - 2024-03-22

### Fixes

  * Fixed a parse bug that wrong result may be happen when:

    * `:skip_lines` is used
    * `:row_separator` is `"\r\n"`
    * There is a line that includes `\n` as a column value

    Reported by Ryo Tsukamoto.

    GH-296

### Thanks

  * Ryo Tsukamoto

## 3.2.8 - 2023-11-08

### Improvements

  * Added `CSV::InvalidEncodingError`.

    Patch by Kosuke Shibata.

    GH-287

### Thanks

  * Kosuke Shibata

## 3.2.7 - 2023-06-26

### Improvements

  * Removed an unused internal variable.
    [GH-273](https://github.com/ruby/csv/issues/273)
    [Patch by Mau Magnaguagno]

  * Changed to use `https://` instead of `http://` in documents.
    [GH-274](https://github.com/ruby/csv/issues/274)
    [Patch by Vivek Bharath Akupatni]

  * Added prefix to a helper module in test.
    [GH-278](https://github.com/ruby/csv/issues/278)
    [Patch by Luke Gruber]

  * Added a documentation for `liberal_parsing: {backslash_quotes: true}`.
    [GH-280](https://github.com/ruby/csv/issues/280)
    [Patch by Mark Schneider]

### Fixes

  * Fixed a wrong execution result in documents.
    [GH-276](https://github.com/ruby/csv/issues/276)
    [Patch by Yuki Tsujimoto]

  * Fixed a bug that the same line is used multiple times.
    [GH-279](https://github.com/ruby/csv/issues/279)
    [Reported by Gabriel Nagy]

### Thanks

  * Mau Magnaguagno

  * Vivek Bharath Akupatni

  * Yuki Tsujimoto

  * Luke Gruber

  * Mark Schneider

  * Gabriel Nagy

## 3.2.6 - 2022-12-08

### Improvements

  * `CSV#read` consumes the same lines with other methods like
    `CSV#shift`.
    [[GitHub#258](https://github.com/ruby/csv/issues/258)]
    [Reported by Lhoussaine Ghallou]

  * All `Enumerable` based methods consume the same lines with other
    methods. This may have a performance penalty.
    [[GitHub#260](https://github.com/ruby/csv/issues/260)]
    [Reported by Lhoussaine Ghallou]

  * Simplify some implementations.
    [[GitHub#262](https://github.com/ruby/csv/pull/262)]
    [[GitHub#263](https://github.com/ruby/csv/pull/263)]
    [Patch by Mau Magnaguagno]

### Fixes

  * Fixed `CSV.generate_lines` document.
    [[GitHub#257](https://github.com/ruby/csv/pull/257)]
    [Patch by Sampat Badhe]

### Thanks

  * Sampat Badhe

  * Lhoussaine Ghallou

  * Mau Magnaguagno

## 3.2.5 - 2022-08-26

### Improvements

  * Added `CSV.generate_lines`.
    [[GitHub#255](https://github.com/ruby/csv/issues/255)]
    [Reported by OKURA Masafumi]
    [[GitHub#256](https://github.com/ruby/csv/pull/256)]
    [Patch by Eriko Sugiyama]

### Thanks

  * OKURA Masafumi

  * Eriko Sugiyama

## 3.2.4 - 2022-08-22

### Improvements

  * Cleaned up internal implementations.
    [[GitHub#249](https://github.com/ruby/csv/pull/249)]
    [[GitHub#250](https://github.com/ruby/csv/pull/250)]
    [[GitHub#251](https://github.com/ruby/csv/pull/251)]
    [Patch by Mau Magnaguagno]

  * Added support for RFC 3339 style time.
    [[GitHub#248](https://github.com/ruby/csv/pull/248)]
    [Patch by Thierry Lambert]

  * Added support for transcoding String CSV. Syntax is
    `from-encoding:to-encoding`.
    [[GitHub#254](https://github.com/ruby/csv/issues/254)]
    [Reported by Richard Stueven]

  * Added quoted information to `CSV::FieldInfo`.
    [[GitHub#254](https://github.com/ruby/csv/pull/253)]
    [Reported by Hirokazu SUZUKI]

### Fixes

  * Fixed a link in documents.
    [[GitHub#244](https://github.com/ruby/csv/pull/244)]
    [Patch by Peter Zhu]

### Thanks

  * Peter Zhu

  * Mau Magnaguagno

  * Thierry Lambert

  * Richard Stueven

  * Hirokazu SUZUKI

## 3.2.3 - 2022-04-09

### Improvements

  * Added contents summary to `CSV::Table#inspect`.
    [GitHub#229][Patch by Eriko Sugiyama]
    [GitHub#235][Patch by Sampat Badhe]

  * Suppressed `$INPUT_RECORD_SEPARATOR` deprecation warning by
    `Warning.warn`.
    [GitHub#233][Reported by Jean byroot Boussier]

  * Improved error message for liberal parsing with quoted values.
    [GitHub#231][Patch by Nikolay Rys]

  * Fixed typos in documentation.
    [GitHub#236][Patch by Sampat Badhe]

  * Added `:max_field_size` option and deprecated `:field_size_limit` option.
    [GitHub#238][Reported by Dan Buettner]

  * Added `:symbol_raw` to built-in header converters.
    [GitHub#237][Reported by taki]
    [GitHub#239][Patch by Eriko Sugiyama]

### Fixes

  * Fixed a bug that some texts may be dropped unexpectedly.
    [Bug #18245][ruby-core:105587][Reported by Hassan Abdul Rehman]

  * Fixed a bug that `:field_size_limit` doesn't work with not complex row.
    [GitHub#238][Reported by Dan Buettner]

### Thanks

  * Hassan Abdul Rehman

  * Eriko Sugiyama

  * Jean byroot Boussier

  * Nikolay Rys

  * Sampat Badhe

  * Dan Buettner

  * taki

## 3.2.2 - 2021-12-24

### Improvements

  * Added a validation for invalid option combination.
    [GitHub#225][Patch by adamroyjones]

  * Improved documentation for developers.
    [GitHub#227][Patch by Eriko Sugiyama]

### Fixes

  * Fixed a bug that all of `ARGF` contents may not be consumed.
    [GitHub#228][Reported by Rafael Navaza]

### Thanks

  * adamroyjones

  * Eriko Sugiyama

  * Rafael Navaza

## 3.2.1 - 2021-10-23

### Improvements

  * doc: Fixed wrong class name.
    [GitHub#217][Patch by Vince]

  * Changed to always use `"\n"` for the default row separator on Ruby
    3.0 or later because `$INPUT_RECORD_SEPARATOR` was deprecated
    since Ruby 3.0.

  * Added support for Ractor.
    [GitHub#218][Patch by rm155]

    * Users who want to use the built-in converters in non-main
      Ractors need to call `Ractor.make_shareable(CSV::Converters)`
      and/or `Ractor.make_shareable(CSV::HeaderConverters)` before
      creating non-main Ractors.

### Thanks

  * Vince

  * Joakim Antman

  * rm155

## 3.2.0 - 2021-06-06

### Improvements

  * `CSV.open`: Added support for `:newline` option.
    [GitHub#198][Patch by Nobuyoshi Nakada]

  * `CSV::Table#each`: Added support for column mode with duplicated
    headers.
    [GitHub#206][Reported by Yaroslav Berezovskiy]

  * `Object#CSV`: Added support for Ruby 3.0.

  * `CSV::Row`: Added support for pattern matching.
    [GitHub#207][Patch by Kevin Newton]

### Fixes

  * Fixed typos in documentation.
    [GitHub#196][GitHub#205][Patch by Sampat Badhe]

### Thanks

  * Sampat Badhe

  * Nobuyoshi Nakada

  * Yaroslav Berezovskiy

  * Kevin Newton

## 3.1.9 - 2020-11-23

### Fixes

  * Fixed a compatibility bug that the line to be processed by
    `skip_lines:` has a row separator.
    [GitHub#194][Reported by Josef Šimánek]

### Thanks

  * Josef Šimánek

## 3.1.8 - 2020-11-18

### Improvements

  * Improved documentation.
    [Patch by Burdette Lamar]

### Thanks

  * Burdette Lamar

## 3.1.7 - 2020-08-04

### Improvements

  * Improved document.
    [GitHub#158][GitHub#160][GitHub#161]
    [Patch by Burdette Lamar]

  * Updated required Ruby version to 2.5.0 or later.
    [GitHub#159]
    [Patch by Gabriel Nagy]

  * Removed stringio 0.1.3 or later dependency.

### Thanks

  * Burdette Lamar

  * Gabriel Nagy

## 3.1.6 - 2020-07-20

### Improvements

  * Improved document.
    [GitHub#127][GitHub#135][GitHub#136][GitHub#137][GitHub#139][GitHub#140]
    [GitHub#141][GitHub#142][GitHub#143][GitHub#145][GitHub#146][GitHub#148]
    [GitHub#148][GitHub#151][GitHub#152][GitHub#154][GitHub#155][GitHub#157]
    [Patch by Burdette Lamar]

  * `CSV.open`: Added support for `undef: :replace`.
    [GitHub#129][Patch by Koichi ITO]

  * `CSV.open`: Added support for `invalid: :replace`.
    [GitHub#129][Patch by Koichi ITO]

  * Don't run quotable check for invalid encoding field values.
    [GitHub#131][Patch by Koichi ITO]

  * Added support for specifying the target indexes and names to
    `force_quotes:`.
    [GitHub#153][Reported by Aleksandr]

  * `CSV.generate`: Changed to use the encoding of the first non-ASCII
    field rather than the encoding of ASCII only field.

  * Changed to require the stringio gem 0.1.3 or later.

### Thanks

  * Burdette Lamar

  * Koichi ITO

  * Aleksandr

## 3.1.5 - 2020-05-18

### Improvements

  * Improved document.
    [GitHub#124][Patch by Burdette Lamar]

### Fixes

  * Added missing document files.
    [GitHub#125][Reported by joast]

### Thanks

  * Burdette Lamar

  * joast

## 3.1.4 - 2020-05-17

### Improvements

  * Improved document.
    [GitHub#122][Patch by Burdette Lamar]

  * Stopped to dropping stack trace for exception caused by
    `CSV.parse_line`.
    [GitHub#120][Reported by Kyle d'Oliveira]

### Fixes

  * Fixed a bug that `:write_nil_value` or `:write_empty_value` don't
    work with non `String` objects.
    [GitHub#123][Reported by asm256]

### Thanks

  * Burdette Lamar

  * asm256

  * Kyle d'Oliveira

## 3.1.3 - 2020-05-09

### Improvements

  * `CSV::Row#dup`: Copied deeply.
    [GitHub#108][Patch by Jim Kane]

### Fixes

  * Fixed a infinite loop bug for zero length match `skip_lines`.
    [GitHub#110][Patch by Mike MacDonald]

  * `CSV.generate`: Fixed a bug that encoding isn't set correctly.
    [GitHub#110][Patch by Seiei Miyagi]

  * Fixed document for the `:strip` option.
    [GitHub#114][Patch by TOMITA Masahiro]

  * Fixed a parse bug when split charcter exists in middle of column
    value.
    [GitHub#115][Reported by TOMITA Masahiro]

### Thanks

  * Jim Kane

  * Mike MacDonald

  * Seiei Miyagi

  * TOMITA Masahiro

## 3.1.2 - 2019-10-12

### Improvements

  * Added `:col_sep` check.
    [GitHub#94][Reported by Florent Beaurain]

  * Suppressed warnings.
    [GitHub#96][Patch by Nobuyoshi Nakada]

  * Improved documentation.
    [GitHub#101][GitHub#102][Patch by Vitor Oliveira]

### Fixes

  * Fixed a typo in documentation.
    [GitHub#95][Patch by Yuji Yaginuma]

  * Fixed a multibyte character handling bug.
    [GitHub#97][Patch by koshigoe]

  * Fixed typos in documentation.
    [GitHub#100][Patch by Vitor Oliveira]

  * Fixed a bug that seeked `StringIO` isn't accepted.
    [GitHub#98][Patch by MATSUMOTO Katsuyoshi]

  * Fixed a bug that `CSV.generate_line` doesn't work with
    `Encoding.default_internal`.
    [GitHub#105][Reported by David Rodríguez]

### Thanks

  * Florent Beaurain

  * Yuji Yaginuma

  * Nobuyoshi Nakada

  * koshigoe

  * Vitor Oliveira

  * MATSUMOTO Katsuyoshi

  * David Rodríguez

## 3.1.1 - 2019-04-26

### Improvements

  * Added documentation for `strip` option.
    [GitHub#88][Patch by hayashiyoshino]

  * Added documentation for `write_converters`, `write_nil_value` and
    `write_empty_value` options.
    [GitHub#87][Patch by Masafumi Koba]

  * Added documentation for `quote_empty` option.
    [GitHub#89][Patch by kawa\_tech]

### Fixes

  * Fixed a bug that `strip; true` removes a newline.

### Thanks

  * hayashiyoshino

  * Masafumi Koba

  * kawa\_tech

## 3.1.0 - 2019-04-17

### Fixes

  * Fixed a backward incompatibility bug that `CSV#eof?` may raises an
    error.
    [GitHub#86][Reported by krororo]

### Thanks

  * krororo

## 3.0.9 - 2019-04-15

### Fixes

  * Fixed a test for Windows.

## 3.0.8 - 2019-04-11

### Fixes

  * Fixed a bug that `strip: String` doesn't work.

## 3.0.7 - 2019-04-08

### Improvements

  * Improve parse performance 1.5x by introducing loose parser.

### Fixes

  * Fix performance regression in 3.0.5.

  * Fix a bug that `CSV#line` returns wrong value when you
    use `quote_char: nil`.

## 3.0.6 - 2019-03-30

### Improvements

  * `CSV.foreach`: Added support for `mode`.

## 3.0.5 - 2019-03-24

### Improvements

  * Added `:liberal_parsing => {backslash_quote: true}` option.
    [GitHub#74][Patch by 284km]

  * Added `:write_converters` option.
    [GitHub#73][Patch by Danillo Souza]

  * Added `:write_nil_value` option.

  * Added `:write_empty_value` option.

  * Improved invalid byte line number detection.
    [GitHub#78][Patch by Alyssa Ross]

  * Added `quote_char: nil` optimization.
    [GitHub#79][Patch by 284km]

  * Improved error message.
    [GitHub#81][Patch by Andrés Torres]

  * Improved IO-like implementation for `StringIO` data.
    [GitHub#80][Patch by Genadi Samokovarov]

  * Added `:strip` option.
    [GitHub#58]

### Fixes

  * Fixed a compatibility bug that `CSV#each` doesn't care `CSV#shift`.
    [GitHub#76][Patch by Alyssa Ross]

  * Fixed a compatibility bug that `CSV#eof?` doesn't care `CSV#each`
    and `CSV#shift`.
    [GitHub#77][Reported by Chi Leung]

  * Fixed a compatibility bug that invalid line isn't ignored.
    [GitHub#82][Reported by krororo]

  * Fixed a bug that `:skip_lines` doesn't work with multibyte characters data.
    [GitHub#83][Reported by ff2248]

### Thanks

  * Alyssa Ross

  * 284km

  * Chi Leung

  * Danillo Souza

  * Andrés Torres

  * Genadi Samokovarov

  * krororo

  * ff2248

## 3.0.4 - 2019-01-25

### Improvements

  * Removed duplicated `CSV::Row#include?` implementations.
    [GitHub#69][Patch by Max Schwenk]

  * Removed duplicated `CSV::Row#header?` implementations.
    [GitHub#70][Patch by Max Schwenk]

### Fixes

  * Fixed a typo in document.
    [GitHub#72][Patch by Artur Beljajev]

  * Fixed a compatibility bug when row headers are changed.
    [GitHub#71][Reported by tomoyuki kosaka]

### Thanks

  * Max Schwenk

  * Artur Beljajev

  * tomoyuki kosaka

## 3.0.3 - 2019-01-12

### Improvements

  * Migrated benchmark tool to benchmark-driver from benchmark-ips.
    [GitHub#57][Patch by 284km]

  * Added `liberal_parsing: {double_quote_outside_quote: true}` parse
    option.
    [GitHub#66][Reported by Watson]

  * Added `quote_empty:` write option.
    [GitHub#35][Reported by Dave Myron]

### Fixes

  * Fixed a compatibility bug that `CSV.generate` always return
    `ASCII-8BIT` encoding string.
    [GitHub#63][Patch by Watson]

  * Fixed a compatibility bug that `CSV.parse("", headers: true)`
    doesn't return `CSV::Table`.
    [GitHub#64][Reported by Watson][Patch by 284km]

  * Fixed a compatibility bug that multiple-characters column
    separator doesn't work.
    [GitHub#67][Reported by Jesse Reiss]

  * Fixed a compatibility bug that double `#each` parse twice.
    [GitHub#68][Reported by Max Schwenk]

### Thanks

  * Watson

  * 284km

  * Jesse Reiss

  * Dave Myron

  * Max Schwenk

## 3.0.2 - 2018-12-23

### Improvements

  * Changed to use strscan in parser.
    [GitHub#52][Patch by 284km]

  * Improves CSV write performance.
    3.0.2 will be about 2 times faster than 3.0.1.

  * Improves CSV parse performance for complex case.
    3.0.2 will be about 2 times faster than 3.0.1.

### Fixes

  * Fixed a parse error bug for new line only input with `headers` option.
    [GitHub#53][Reported by Chris Beer]

  * Fixed some typos in document.
    [GitHub#54][Patch by Victor Shepelev]

### Thanks

  * 284km

  * Chris Beer

  * Victor Shepelev

## 3.0.1 - 2018-12-07

### Improvements

  * Added a test.
    [GitHub#38][Patch by 284km]

  * `CSV::Row#dup`: Changed to duplicate internal data.
    [GitHub#39][Reported by André Guimarães Sakata]

  * Documented `:nil_value` and `:empty_value` options.
    [GitHub#41][Patch by OwlWorks]

  * Added support for separator detection for non-seekable inputs.
    [GitHub#45][Patch by Ilmari Karonen]

  * Removed needless code.
    [GitHub#48][Patch by Espartaco Palma]

  * Added support for parsing header only CSV with `headers: true`.
    [GitHub#47][Patch by Kazuma Shibasaka]

  * Added support for coverage report in CI.
    [GitHub#48][Patch by Espartaco Palma]

  * Improved auto CR row separator detection.
    [GitHub#51][Reported by Yuki Kurihara]

### Fixes

  * Fixed a typo in document.
    [GitHub#40][Patch by Marcus Stollsteimer]

### Thanks

  * 284km

  * André Guimarães Sakata

  * Marcus Stollsteimer

  * OwlWorks

  * Ilmari Karonen

  * Espartaco Palma

  * Kazuma Shibasaka

  * Yuki Kurihara

## 3.0.0 - 2018-06-06

### Fixes

  * Fixed a bug that header isn't returned for empty row.
    [GitHub#37][Patch by Grace Lee]

### Thanks

  * Grace Lee

## 1.0.2 - 2018-05-03

### Improvements

  * Split file for CSV::VERSION

  * Code cleanup: Split csv.rb into a more manageable structure
    [GitHub#19][Patch by Espartaco Palma]
    [GitHub#20][Patch by Steven Daniels]

  * Use CSV::MalformedCSVError for invalid encoding line
    [GitHub#26][Reported by deepj]

  * Support implicit Row <-> Array conversion
    [Bug #10013][ruby-core:63582][Reported by Dawid Janczak]

  * Update class docs
    [GitHub#32][Patch by zverok]

  * Add `Row#each_pair`
    [GitHub#33][Patch by zverok]

  * Improve CSV performance
    [GitHub#30][Patch by Watson]

  * Add :nil_value and :empty_value option

### Fixes

  * Fix a bug that "bom|utf-8" doesn't work
    [GitHub#23][Reported by Pavel Lobashov]

  * `CSV::Row#to_h`, `#to_hash`: uses the same value as `Row#[]`
    [Bug #14482][Reported by tomoya ishida]

  * Make row separator detection more robust
    [GitHub#25][Reported by deepj]

  * Fix a bug that too much separator when col_sep is `" "`
    [Bug #8784][ruby-core:63582][Reported by Sylvain Laperche]

### Thanks

  * Espartaco Palma

  * Steven Daniels

  * deepj

  * Dawid Janczak

  * zverok

  * Watson

  * Pavel Lobashov

  * tomoya ishida

  * Sylvain Laperche

  * Ryunosuke Sato

## 1.0.1 - 2018-02-09

### Improvements

  * `CSV::Table#delete`: Added bulk delete support. You can delete
    multiple rows and columns at once.
    [GitHub#4][Patch by Vladislav]

  * Updated Gem description.
    [GitHub#11][Patch by Marcus Stollsteimer]

  * Code cleanup.
    [GitHub#12][Patch by Marcus Stollsteimer]
    [GitHub#14][Patch by Steven Daniels]
    [GitHub#18][Patch by takkanm]

  * `CSV::Table#dig`: Added.
    [GitHub#15][Patch by Tomohiro Ogoke]

  * `CSV::Row#dig`: Added.
    [GitHub#15][Patch by Tomohiro Ogoke]

  * Added ISO 8601 support to date time converter.
    [GitHub#16]

### Fixes

  * Fixed wrong `CSV::VERSION`.
    [GitHub#10][Reported by Marcus Stollsteimer]

  * `CSV.generate`: Fixed a regression bug that `String` argument is
    ignored.
    [GitHub#13][Patch by pavel]

### Thanks

  * Vladislav

  * Marcus Stollsteimer

  * Steven Daniels

  * takkanm

  * Tomohiro Ogoke

  * pavel
