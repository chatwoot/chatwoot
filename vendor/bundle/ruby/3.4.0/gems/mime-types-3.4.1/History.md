# Changelog

## 3.4.1 / 2021-11-16

- 1 bugfix:

  - Fixed a Ruby &lt; 2.3 incompatibility introduced by the use of standardrb,
    where `<<-` heredocs were converted to `<<~` heredocs. These have been
    reverted back to `<<-` with the indentation kept and a `.strip` call
    to prevent excess whitespace.

## 3.4.0 / 2021-11-15

- 1 minor enhancement:

  - Added a new field to `MIME::Type` for checking provisional registrations
    from IANA. [#157]

- Documentation:

  - Kevin Menard synced the documentation so that all examples are correct.
    [#153]

- Administrivia:

  - Added Ruby 3.0 to the CI test matrix. Added `windows/jruby` to the
    CI exclusion list; it refuses to run successfully.
  - Removed the Travis CI configuration and changed it to Github Workflows
    [#150]. Removed Coveralls configuration.
  - Igor Victor added TruffleRuby to the Travis CI configuration. [#149]
  - Koichi ITO loosened an excessively tight dependency. [#147]
  - Started using `standardrb` for Ruby formatting and validation.
  - Moved `deps:top` functionality to a support file.

## 3.3.1 / 2019-12-26

- 1 minor bugfix:

  - Al Snow fixed a warning with MIME::Types::Logger producing a warning
    because Ruby 2.7 introduces numbered block parameters. Because of the way
    that the MIME::Types::Logger works for deprecation messages, the
    initializer parameters had been named `_1`, `_2`, and `_3`. This has now
    been resolved. [#146]

- Administrivia:

  - Olle Jonsson removed an outdated Travis configuration option (`sudo: false`). [#142]

## 3.3 / 2019-09-04

- 1 minor enhancement

  - Jean Boussier reduced memory usage for Ruby versions 2.3 or higher by
    interning various string values in each type. This is done with a
    backwards-compatible call that _freezes_ the strings on older versions of
    Ruby. [#141]

- Administrivia:

  - Nicholas La Roux updated Travis build configurations. [#139]

## 3.2.2 / 2018-08-12

- Hiroto Fukui removed a stray `debugger` statement that I had used in
  producing v3.2.1. [#137]

## 3.2.1 / 2018-08-12

- A few bugs related to MIME::Types::Container and its use in the
  mime-types-data helper tools reared their head because I released 3.2
  before verifying against mime-types-data.

## 3.2 / 2018-08-12

- 2 minor enhancements

  - Janko Marohnić contributed a change to `MIME::Type#priority_order` that
    should improve on strict sorting when dealing with MIME types that appear
    to be in the same family even if strict sorting would cause an
    unregistered type to be sorted first. [#132]

  - Dillon Welch contributed a change that added `frozen_string_literal: true` to files so that modern Rubies can automatically reduce duplicate
    string allocations. [#135]

- 2 bug fixes

  - Burke Libbey fixed a problem with cached data loading. [#126]

  - Resolved an issue where Enumerable#inject returns `nil` when provided an
    empty enumerable and a default value has not been provided. This is
    because when Enumerable#inject isn't provided a starting value, the first
    value is used as the default value. In every case where this error was
    happening, the result was supposed to be an array containing Set objects
    so they can be reduced to a single Set. [#117], [#127], [#134]

  - Fixed an uncontrolled growth bug in MIME::Types::Container where a key
    miss would create a new entry with an empty Set in the container. This
    was working as designed (this particular feature was heavily used during
    MIME::Type registry construction), but the design was flawed in that it
    did not have any way of determining the difference between construction
    and querying. This would mean that, if you have a function in your web
    app that queries the MIME::Types registry by extension, the extension
    registry would grow uncontrollably. [#136]

- Deprecations:

  - Lazy loading (`$RUBY_MIME_TYPES_LAZY_LOAD`) has been deprecated.

- Documentation Changes:

  - Supporting files are now Markdown instead of rdoc, except for the README.

  - The history file has been modified to remove all history prior to 3.0.
    This history can be found in previous commits.

  - A spelling error was corrected by Edward Betts ([#129]).

- Administrivia:

  - CI configuration for more modern versions of Ruby were added by Nicolas
    Leger ([#130]), Jun Aruga ([#125]), and Austin Ziegler. Removed
    ruby-head-clang and rbx (Rubinius) from CI.

  - Fixed tests which were asserting equality against nil, which will become
    an error in Minitest 6.

## 3.1 / 2016-05-22

- 1 documentation change:

  - Tim Smith (@tas50) updated the build badges to be SVGs to improve
    readability on high-density (retina) screens with pull request [#112].

- 3 bug fixes

  - A test for `MIME::Types::Cache` fails under Ruby 2.3 because of frozen
    strings, [#118]. This has been fixed.

  - The JSON data has been incorrectly encoded since the release of
    mime-types 3 on the `xrefs` field, because of the switch to using a Set
    to store cross-reference information. This has been fixed.

  - A tentative fix for [#117] has been applied, removing the only circular
    require dependencies that exist (and for which there was code to prevent,
    but the current fix is simpler). I have no way to verify this fix and
    depending on how things are loaded by `delayed_job`, this fix may not be
    sufficient.

- 1 governance change

  - Updated to Contributor Covenant 1.4.

## 3.0 / 2015-11-21

- 2 governance changes

  - This project and the related mime-types-data project are now exclusively
    MIT licensed. Resolves [#95].

  - All projects under the mime-types organization now have a standard code
    of conduct adapted from the [Contributor Covenant]. This text can be
    found in the [Code-of-Conduct.md] file.

- 3 major changes

  - All methods deprecated in mime-types 2.x have been removed.

  - mime-types now requires Ruby 2.0 compatibility or later. Resolves
    [#97].

  - The registry data has been removed from mime-types and put into
    mime-types-data, maintained and released separately. It can be found at
    [mime-types-data].

- 17 minor changes:

  - `MIME::Type` changes:

    - Changed the way that simplified types representations are created to
      reflect the fact that `x-` prefixes are no longer considered special
      according to IANA. A simplified MIME type is case-folded to lowercase.
      A new keyword parameter, `remove_x_prefix`, can be provided to remove
      `x-` prefixes.

    - Improved initialization with an Array works so that extensions do not
      need to be wrapped in another array. This means that `%w(text/yaml yaml yml)` works in the same way that `['text/yaml', %w(yaml yml)]` did (and
      still does).

    - Changed `priority_compare` to conform with attributes that no longer
      exist.

    - Changed the internal implementation of extensions to use a frozen Set.

    - When extensions are set or modified with `add_extensions`, the primary
      registry will be informed of a need to reindex extensions. Resolves
      [#84].

    - The preferred extension can be set explicitly. If not set, it will be
      the first extension. If the preferred extension is not in the extension
      list, it will be added.

    - Improved how xref URLs are generated.

    - Converted `obsolete`, `registered` and `signature` to `attr_accessors`.

  - `MIME::Types` changes:

    - Modified `MIME::Types.new` to track instances of `MIME::Types` so that
      they can be told to reindex the extensions as necessary.

    - Removed `data_version` attribute.

    - Changed `#[]` so that the `complete` and `registered` flags are
      keywords instead of a generic options parameter.

    - Extracted the class methods to a separate file.

    - Changed the container implementation to use a Set instead of an Array
      to prevent data duplication. Resolves [#79].

  - `MIME::Types::Cache` changes:

    - Caching is now based on the data gem version instead of the mime-types
      version.

    - Caching is compatible with columnar registry stores.

  - `MIME::Types::Loader` changes:

    - `MIME::Types::Loader::PATH` has been removed and replaced with
      `MIME::Types::Data::PATH` from the mime-types-data gem. The environment
      variable `RUBY_MIME_TYPES_DATA` is still used.

    - Support for the long-deprecated mime-types v1 format has been removed.

    - The registry is default loaded from the columnar store by default. The
      internal format of the columnar store has changed; many of the boolean
      flags are now loaded from a single file. Resolves [#85].

[#79]: https://github.com/mime-types/ruby-mime-types/pull/79
[#84]: https://github.com/mime-types/ruby-mime-types/pull/84
[#85]: https://github.com/mime-types/ruby-mime-types/pull/85
[#95]: https://github.com/mime-types/ruby-mime-types/pull/95
[#97]: https://github.com/mime-types/ruby-mime-types/pull/97
[#112]: https://github.com/mime-types/ruby-mime-types/pull/112
[#117]: https://github.com/mime-types/ruby-mime-types/issues/117
[#118]: https://github.com/mime-types/ruby-mime-types/pull/118
[#125]: https://github.com/mime-types/ruby-mime-types/pull/125
[#126]: https://github.com/mime-types/ruby-mime-types/pull/126
[#127]: https://github.com/mime-types/ruby-mime-types/issues/127
[#129]: https://github.com/mime-types/ruby-mime-types/pull/129
[#130]: https://github.com/mime-types/ruby-mime-types/pull/130
[#127]: https://github.com/mime-types/ruby-mime-types/issues/127
[#132]: https://github.com/mime-types/ruby-mime-types/pull/132
[#134]: https://github.com/mime-types/ruby-mime-types/issues/134
[#135]: https://github.com/mime-types/ruby-mime-types/pull/135
[#136]: https://github.com/mime-types/ruby-mime-types/issues/136
[#137]: https://github.com/mime-types/ruby-mime-types/pull/137
[#139]: https://github.com/mime-types/ruby-mime-types/pull/139
[#141]: https://github.com/mime-types/ruby-mime-types/pull/141
[#142]: https://github.com/mime-types/ruby-mime-types/pull/142
[#146]: https://github.com/mime-types/ruby-mime-types/pull/146
[#147]: https://github.com/mime-types/ruby-mime-types/pull/147
[#149]: https://github.com/mime-types/ruby-mime-types/pull/149
[#150]: https://github.com/mime-types/ruby-mime-types/pull/150
[#153]: https://github.com/mime-types/ruby-mime-types/pull/153
[code-of-conduct.md]: Code-of-Conduct_md.html
[contributor covenant]: http://contributor-covenant.org
[mime-types-data]: https://github.com/mime-types/mime-types-data
