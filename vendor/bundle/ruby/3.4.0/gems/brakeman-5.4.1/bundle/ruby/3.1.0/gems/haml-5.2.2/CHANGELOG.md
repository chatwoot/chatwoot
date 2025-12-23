# Haml Changelog

## 5.2.2
Released on July 27, 2021
([diff](https://github.com/haml/haml/compare/v5.2.1...v5.2.2)).

* Support for adding Annotations to Haml output (a Rails feature 6.1+)
* Expanded test matrix to include Ruby 3.0 and Rails 6.1
* Only testing Ruby 2.7+ and Rails 5.2+

## 5.2.1

Released on November 30, 2020
([diff](https://github.com/haml/haml/compare/v5.2.0...v5.2.1)).

* Add in improved "multiline" support for attributes [#1043](https://github.com/haml/haml/issues/1043)

## 5.2

Released on September 28, 2020
([diff](https://github.com/haml/haml/compare/v5.1.2...v5.2.0)).

* Fix crash in the attribute optimizer when `#inspect` is overridden in TrueClass / FalseClass [#972](https://github.com/haml/haml/issues/972)
* Do not HTML-escape templates that are declared to be plaintext [#1014](https://github.com/haml/haml/issues/1014) (Thanks [@cesarizu](https://github.com/cesarizu))
* Class names are no longer ordered alphabetically, and now follow a new specification as laid out in REFERENCE [#306](https://github.com/haml/haml/issues/306)

## 5.1.2

Released on August 6, 2019
([diff](https://github.com/haml/haml/compare/v5.1.1...v5.1.2)).

* Fix crash in some environments such as New Relic by unfreezing string literals for ParseNode#inspect. [#1016](https://github.com/haml/haml/pull/1016) (thanks [Jalyna](https://github.com/jalyna))

## 5.1.1

Released on May 25, 2019
([diff](https://github.com/haml/haml/compare/v5.1.0...v5.1.1)).

* Fix NameError bug that happens on ruby 2.6.1-2.6.3 + haml 5.1.0 + rails < 5.1 + erubi. (Akira Matsuda)

## 5.1.0

Released on May 16, 2019
([diff](https://github.com/haml/haml/compare/v5.0.4...v5.1.0)).

* Rails 6 support [#1008](https://github.com/haml/haml/pull/1008) (thanks [Seb Jacobs](https://github.com/sebjacobs))
* Add `escape_filter_interpolations` option for backwards compatibility with haml 4 defaults [#984](https://github.com/haml/haml/pull/984) (thanks [Will Jordan](https://github.com/wjordan))
* Fix error on empty :javascript and :css filter blocks [#986](https://github.com/haml/haml/pull/986) (thanks [Will Jordan](https://github.com/wjordan))
* Respect changes in Haml::Options.defaults in `Haml::TempleEngine` options (Takashi Kokubun)
* Un-freeze TempleEngine precompiled string literals [#983](https://github.com/haml/haml/pull/983) (thanks [Will Jordan](https://github.com/wjordan))
* Various performance/memory improvements [#965](https://github.com/haml/haml/pull/965), [#966](https://github.com/haml/haml/pull/966), [#963](https://github.com/haml/haml/pull/963) (thanks [Dillon Welch](https://github.com/oniofchaos))
* Enable `frozen_string_literal` magic comment for all .rb files [#967](https://github.com/haml/haml/pull/967) (thanks [Dillon Welch](https://github.com/oniofchaos))

## 5.0.4

Released on October 13, 2017
([diff](https://github.com/haml/haml/compare/v5.0.3...v5.0.4)).

* Fix `haml -c --stdin` regression in 5.0.2. [#958](https://github.com/haml/haml/pull/958) (thanks [Timo Göllner](https://github.com/TeaMoe))
* Ruby 2.5 support (it wasn't working due to Ripper API change). (Akira Matsuda)

## 5.0.3

Released on September 7, 2017
([diff](https://github.com/haml/haml/compare/v5.0.2...v5.0.3)).

* Use `String#dump` instead of `String#inspect` to generate string literal. (Takashi Kokubun)
* Fix Erubi superclass mismatch error. [#952](https://github.com/haml/haml/pull/952) (thanks [Robin Daugherty](https://github.com/RobinDaugherty))

## 5.0.2

Released on August 1, 2017
([diff](https://github.com/haml/haml/compare/v5.0.1...v5.0.2)).

* Let `haml -c` fail if generated Ruby code is syntax error. [#880](https://github.com/haml/haml/issues/880) (Takashi Kokubun)
* Fix `NoMethodError` bug caused with Sprockets 3 and :sass filter. [#930](https://github.com/haml/haml/pull/930) (thanks [Gonzalez Maximiliano](https://github.com/emaxi))
* Fix `list_of` helper with multi-line content. [#933](https://github.com/haml/haml/pull/933) (thanks [Benoit Larroque](https://github.com/zetaben))
* Optimize rendering performance by changing timing to fix textareas. [#941](https://github.com/haml/haml/pull/941) (Takashi Kokubun)
* Fix `TypeError` with empty :ruby filter. [#942](https://github.com/haml/haml/pull/942) (Takashi Kokubun)
* Fix inconsistent attribute sort order. (Takashi Kokubun)

## 5.0.1

Released on May 3, 2017
([diff](https://github.com/haml/haml/compare/v5.0.0...v5.0.1)).

* Fix parsing attributes including string interpolation. [#917](https://github.com/haml/haml/pull/917) [#921](https://github.com/haml/haml/issues/921)
* Stop distributing test files in gem package and allow installing on Windows.
* Use ActionView's Erubi/Erubis handler for erb filter only on ActionView. [#914](https://github.com/haml/haml/pull/914)

## 5.0.0

Released on April 26, 2017
([diff](https://github.com/haml/haml/compare/4.0.7...v5.0.0)).

Breaking Changes

* Haml now requires Ruby 2.0.0 or above.
* Rails 3 is no longer supported, matching the official
  [Maintenance Policy for Ruby on Rails](http://weblog.rubyonrails.org/2013/2/24/maintenance-policy-for-ruby-on-rails/).
  Use Haml 4 if you want to use Rails 3.
  (Tee Parham)
* Remove `:ugly` option ([#894](https://github.com/haml/haml/pull/894))
* The `haml` command's debug option (`-d`) no longer executes the Haml code, but
  rather checks the generated Ruby syntax for errors.
* Drop parser/compiler accessor from `Haml::Engine`. Modify `Haml::Engine#initialize` options
  or `Haml::Template.options` instead. (Takashi Kokubun)
* Drop dynamic quotes support and always escape `'` for `escape_html`/`escape_attrs` instead.
  Also, escaped results are slightly changed and always unified to the same characters. (Takashi Kokubun)
* Don't preserve newlines in attributes. (Takashi Kokubun)
* HTML escape interpolated code in filters.
  [#770](https://github.com/haml/haml/pull/770)
  (Matt Wildig)

        :javascript
          #{JSON.generate(foo: "bar")}
        Haml 4 output: {"foo":"bar"}
        Haml 5 output: {&quot;foo&quot;:&quot;bar&quot;}

Added

* Add a tracing option. When enabled, Haml will output a data-trace attribute on each tag showing the path
  to the source Haml file from which it was generated. Thanks [Alex Babkin](https://github.com/ababkin).
* Add `haml_tag_if` to render a block, conditionally wrapped in another element (Matt Wildig)
* Support Rails 5.1 Erubi template handler.
* Support Sprockets 3. Thanks [Sam Davies](https://github.com/samphilipd) and [Jeremy Venezia](https://github.com/jvenezia).
* General performance and memory usage improvements. (Akira Matsuda)
* Analyze attribute values by Ripper and render static attributes beforehand. (Takashi Kokubun)
* Optimize attribute rendering about 3x faster. (Takashi Kokubun)
* Add temple gem as dependency and create `Haml::TempleEngine` class.
  Some methods in `Haml::Compiler` are migrated to `Haml::TempleEngine`. (Takashi Kokubun)

Fixed

* Fix for attribute merging. When an attribute method (or literal nested hash)
  was used in an old style attribute hash and there is also a (non-static) new
  style hash there is an error. The fix can result in different behavior in
  some circumstances. See the [commit message](https://github.com/haml/haml/tree/e475b015d3171fb4c4f140db304f7970c787d6e3)
  for detailed info. (Matt Wildig)
* Make escape_once respect hexadecimal references. (Matt Wildig)
* Don't treat the 'data' attribute specially when merging attribute hashes. (Matt Wildig and Norman Clarke)
* Fix #@foo and #$foo style interpolation that was not working in html_safe mode. (Akira Matsuda)
* Allow `@` as tag's class name. Thanks [Joe Bartlett](https://github.com/redoPop).
* Raise `Haml::InvalidAttributeNameError` when attribute name includes invalid characters. (Takashi Kokubun)
* Don't ignore unexpected exceptions on initializing `ActionView::OutputBuffer`. (Takashi Kokubun)

## 4.0.7

Released on August 10, 2015
([diff](https://github.com/haml/haml/compare/4.0.6...4.0.7)).

* Significantly improve performance of regexp used to fix whitespace handling in textareas (thanks [Stan Hu](https://github.com/stanhu)).

## 4.0.6

Released on Dec 1, 2014 ([diff](https://github.com/haml/haml/compare/4.0.5...4.0.6)).

* Fix warning on Ruby 1.8.7 "regexp has invalid interval" (thanks [Elia Schito](https://github.com/elia)).

## 4.0.5

Released on Jan 7, 2014 ([diff](https://github.com/haml/haml/compare/4.0.4...4.0.5)).

* Fix haml_concat appending unescaped HTML after a call to haml_tag.
* Fix for bug whereby when HAML :ugly option is "true",
  ActionView::Helpers::CaptureHelper::capture returns the whole view buffer
  when passed a block that returns nothing (thanks [Mircea
  Moise](https://github.com/mmircea16)).

## 4.0.4

Released on November 5, 2013 ([diff](https://github.com/haml/haml/compare/4.0.3...4.0.4)).

* Check for Rails::Railtie rather than Rails (thanks [Konstantin Shabanov](https://github.com/etehtsea)).
* Parser fix to allow literal '#' with suppress_eval (Matt Wildig).
* Helpers#escape_once works on frozen strings (as does
  ERB::Util.html_escape_once for which it acts as a replacement in
  Rails (thanks [Patrik Metzmacher](https://github.com/patrik)).
* Minor test fix (thanks [Mircea Moise](https://github.com/mmircea16)).

## 4.0.3

Released May 21, 2013 ([diff](https://github.com/haml/haml/compare/4.0.2...4.0.3)).

* Compatibility with newer versions of Rails's Erubis handler.
* Fix Erubis handler for compatibility with Tilt 1.4.x, too.
* Small performance optimization for html_escape.
(thanks [Lachlan Sylvester](https://github.com/lsylvester))
* Documentation fixes.
* Documented some helper methods that were left out of the reference.
(thanks [Shane Riley](https://github.com/shaneriley))

## 4.0.2

Released April 5, 2013 ([diff](https://github.com/haml/haml/compare/4.0.1...4.0.2)).

* Explicitly require Erubis to work around bug in older versions of Tilt.
* Fix :erb filter printing duplicate content in Rails views.
(thanks [Jori Hardman](https://github.com/jorihardman))
* Replace range with slice to reduce objects created by `capture_haml`.
(thanks [Tieg Zaharia](https://github.com/tiegz))
* Correct/improve some documentation.

## 4.0.1

Released March 21, 2013 ([diff](https://github.com/haml/haml/compare/4.0.0...4.0.1)).

* Remove Rails 3.2.3+ textarea hack in favor of a more general solution.
* Fix some performance regressions.
* Fix support for Rails 4 `text_area` helper method.
* Fix data attribute flattening with singleton objects.
(thanks [Alisdair McDiarmid](https://github.com/alisdair))
* Fix support for sass-rails 4.0 beta.
(thanks [Ryunosuke SATO](https://github.com/tricknotes))
* Load "haml/template" in Railtie in order to prevent user options set in a
  Rails initializer from being overwritten
* Don't depend on Rails in haml/template to allow using Haml with ActionView
  but without Rails itself. (thanks [Hunter Haydel](https://github.com/wedgex))

## 4.0.0

* The Haml executable now accepts an `--autoclose` option. You can now
  specify a list of tags that should be autoclosed

* The `:ruby` filter no longer redirects $stdout to the Haml document, as this
  is not thread safe. Instead it provides a `haml_io` local variable, which is
  an IO object that writes to the document.

* HTML5 is now the default output format rather than XHTML. This was already
  the default on Rails 3+, so many users will notice no difference.

* The :sass filter now wraps its output in a style tag, as do the new :less and
  :scss filters. The :coffee filter wraps its output in a script tag.

* Haml now supports only Rails 3 and above, and Ruby 1.8.7 and above. If you
  still need support for Rails 2 and Ruby 1.8.6, please use Haml 3.1.x which
  will continue to be maintained for bug fixes.

* The :javascript and :css filters no longer add CDATA tags when the format is
  html4 or html5. This can be overridden by setting the `cdata` option to
  `true`. CDATA tags are always added when the format is xhtml.

* HTML2Haml has been extracted to a separate gem, creatively named "html2haml".

* The `:erb` filter now uses Rails's safe output buffer to provide XSS safety.

* Haml's internals have been refactored to move the parser, compiler and options
  handling into independent classes, rather than including them all in the
  Engine module. You can also specify your own custom Haml parser or compiler
  class in Haml::Options in order to extend or modify Haml reasonably easily.

* Add an {file:REFERENCE.md#hyphenate_data_attrs-option `:hyphenate_data_attrs`
  option} that converts underscores to hyphens in your HTML5 data keys. This is
  a language change from 3.1 and is enabled by default.
  (thanks to [Andrew Smith](https://github.com/fullsailor))

* All Hash attribute values are now treated as HTML5 data, regardless of key.
  Previously only the "data" key was treated this way. Allowing arbitrary keys
  means you can now easily use this feature for Aria attributes, among other
  uses.
  (thanks to [Elvin Efendi](https://github.com/ElvinEfendi))

* Added `remove_whitespace` option to always remove all whitespace around Haml
  tags. (thanks to [Tim van der Horst](https://github.com/vdh))

* Haml now flattens deeply nested data attribute hashes. For example:

  `.foo{:data => {:a => "b", :c => {:d => "e", :f => "g"}}}`

  would render to:

  `<div class='foo' data-a='b' data-c-d='e' data-c-f='g'></div>`

  (thanks to [Péter Pál Koszta](https://github.com/koszta))

* Filters that rely on third-party template engines are now implemented using
  [Tilt](http://github.com/rtomayko/tilt). Several new filters have been added, namely
  SCSS (:scss), LessCSS, (:less), and Coffeescript (:coffee/:coffeescript).

  Though the list of "official" filters is kept intentionally small, Haml comes
  with a helper method that makes adding support for other Tilt-based template
  engines trivial.

  As of 4.0, Haml will also ship with a "haml-contrib" gem that includes useful
  but less-frequently used filters and helpers. This includes several additional
  filters such as Nokogiri, Yajl, Markaby, and others.

* Generate object references based on `#to_key` if it exists in preference to
  `#id`.

* Performance improvements.
  (thanks to [Chris Heald](https://github.com/cheald))

* Helper `list_of` takes an extra argument that is rendered into list item
  attributes.
  (thanks  [Iain Barnett](http://iainbarnett.me.uk/))

* Fix parser to allow lines ending with `some_method?` to be a Ruby multinline.
  (thanks to [Brad Ediger](https://github.com/bradediger))

* Always use :xhtml format when the mime_type of the rendered template is
  'text/xml'.
  (thanks to [Stephen Bannasch](https://github.com/stepheneb))

* html2haml now includes an `--html-attributes` option.
  (thanks [Stefan Natchev](https://github.com/snatchev))

* Fix for inner whitespace removal in loops.
  (thanks [Richard Michael](https://github.com/richardkmichael))

* Use numeric character references rather than HTML entities when escaping
  double quotes and apostrophes in attributes. This works around some bugs in
  Internet Explorer earlier than version 9.
  (thanks [Doug Mayer](https://github.com/doxavore))

* Fix multiline silent comments: Haml previously did not allow free indentation
  inside multline silent comments.

* Fix ordering bug with partial layouts on Rails.
  (thanks [Sam Pohlenz](https://github.com/spohlenz))

* Add command-line option to suppress script evaluation.

* It's now possible to use Rails's asset helpers inside the Sass and SCSS
  filters. Note that to do so, you must make sure sass-rails is loaded in
  production, usually by moving it out of the assets gem group.

* The Haml project now uses [semantic versioning](http://semver.org/).

## 3.2.0

The Haml 3.2 series was released only as far as 3.2.0.rc.4, but then was
renamed to Haml 4.0 when the project adopted semantic versioning.

## 3.1.8

* Fix for line numbers reported from exceptions in nested blocks
  (thanks to Grant Hutchins & Sabrina Staedt).

## 3.1.7

* Fix for compatibility with Sass 3.2.x.
  (thanks [Michael Westbom](https://github.com/totallymike)).

## 3.1.6

* In indented mode, don't reindent buffers that contain preserved tags, and
  provide a better workaround for Rails 3.2.3's textarea helpers.

## 3.1.5

* Respect Rails' `html_safe` flag when escaping attribute values
  (thanks to [Gerad Suyderhoud](https://github.com/gerad)).

* Fix for Rails 3.2.3 textarea helpers
  (thanks to [James Coleman](https://github.com/jcoleman) and others).

## 3.1.4

* Fix the use of `FormBuilder#block` with a label in Haml.
* Fix indentation after a self-closing tag with dynamic attributes.

## 3.1.3

* Stop partial layouts from being displayed twice.

## 3.1.2

* If the ActionView `#capture` helper is used in a Haml template but without any Haml being run in the block,
  return the value of the block rather than the captured buffer.

* Don't throw errors when text is nested within comments.

* Fix html2haml.

* Fix an issue where destructive modification was sometimes performed on Rails SafeBuffers.

* Use character code entities for attribute value replacements instead of named/keyword entities.

## 3.1.1

* Update the vendored Sass to version 3.1.0.

## 3.1.0

* Don't add a `type` attribute to `<script>` and `<style>` tags generated by filters
  when `:format` is set to `:html5`.

* Add an {file:HAML_REFERENCE.md#escape_attrs-option `:escape_attrs` option}
  that allows attributes to either remain unescaped
  (for things like embedding PHP directives in Haml)
  or to be always escaped rather than `#escape_once`d.
  This can also be used from the command line via `--no-escape-attrs`.

* Allow custom filters to be loaded from the command line.

### Backwards Incompatibilities -- Must Read!

* Get rid of the `--rails` flag for the `haml` executable.
  This flag hasn't been necessary since Rails 2.0.
  Existing Rails 2.0 installations will continue to work.

* Drop support for Hpricot 0.7. 0.8 has been out for nearly two years.

## 3.0.25

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.25).

* HTML-to-Haml conversion now works within Ruby even if Hpricot is loaded before `haml/html`.

## 3.0.24

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.24).

* `html2haml` now properly generates Haml for silent script expressions
  nested within blocks.

* IronRuby compatibility. This is sort of a hack: IronRuby reports its version as 1.9,
  but it doesn't support the encoding APIs, so we treat it as 1.8 instead.

## 3.0.23

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.23).

* Fix the error message for unloadable modules when running the executables under Ruby 1.9.2.

* Fix an error when combining old-style and new-style attributes.

## 3.0.22

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.22).

* Allow an empty line after `case` but before `when`.

* Remove `vendor/sass`, which snuck into the gem by mistake
  and was causing trouble for Heroku users (thanks to [Jacques Crocker](http://railsjedi.com/)).

* Support the Rails 3.1 template handler API.

## 3.0.21

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.21).

* Fix the permissions errors for good.

## 3.0.20

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.20).

* Fix some permissions errors.

## 3.0.19

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.19).

* Fix the `:encoding` option under Ruby 1.9.2.

* Fix interpolated if statement when HTML escaping is enabled.

* Allow the `--unix-newlines` flag to work on Unix, where it's a no-op.

## 3.0.18

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.18).

* Don't require `rake` in the gemspec, for bundler compatibility under
  JRuby. Thanks to [Gordon McCreight](http://www.gmccreight.com/blog).

* Get rid of the annoying RDoc errors on install.

* Disambiguate references to the `Rails` module when `haml-rails` is installed.

* Fix a bug in `haml_tag` that would allow duplicate attributes to be added
  and make `data-` attributes not work.

* Compatibility with Rails 3 final.

## 3.0.17

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.17).

* Understand that mingw counts as Windows.

## 3.0.16

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.16).

* Fix an html2haml ERB-parsing bug where ERB blocks were occasionally
  left without indentation in Haml.

* Fix parsing of `if` and `case` statements whose values were assigned to variables.
  This is still bad style, though.

* Fix `form_for` and `form_tag` when they're passed a block that
  returns a string in a helper.

## 3.0.15

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.15).

There were no changes made to Haml between versions 3.0.14 and 3.0.15.

## 3.0.14

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.14).

* Allow CSS-style classes and ids to contain colons.

* Fix an obscure bug with if statements.

### Rails 3 Support

* Don't use the `#returning` method, which Rails 3 no longer provides.

## 3.0.13

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.13).

## Rails 3 Support

Support for Rails 3 versions prior to beta 4 has been removed.
Upgrade to Rails 3.0.0.beta4 if you haven't already.

### Minor Improvements

* Properly process frozen strings with encoding declarations.

## 3.0.12

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.12).

## Rails 3 Support

Apparently the last version broke in new and exciting ways under Rails 3,
due to the inconsistent load order caused by certain combinations of gems.
3.0.12 hacks around that inconsistency, and *should* be fully Rails 3-compatible.

### Deprecated: Rails 3 Beta 3

Haml's support for Rails 3.0.0.beta.3 has been deprecated.
Haml 3.0.13 will only support 3.0.0.beta.4.

## 3.0.11

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.11).

## 3.0.10

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.10).

### Appengine-JRuby Support

The way we determine the location of the Haml installation
no longer breaks the version of JRuby
used by [`appengine-jruby`](http://code.google.com/p/appengine-jruby/).

### Bug Fixes

* Single-line comments are now handled properly by `html2haml`.

## 3.0.9

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.9).

There were no changes made to Haml between versions 3.0.8 and 3.0.9.
A bug in Gemcutter caused the gem to be uploaded improperly.

## 3.0.8

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.8).

* Fix a bug with Rails versions prior to Rails 3.

## 3.0.7

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.7).

### Encoding Support

Haml 3.0.7 adds support for Ruby-style `-# coding:` comments
for declaring the encoding of a template.
For details see {file:HAML_REFERENCE.md#encodings the reference}.

This also slightly changes the behavior of Haml when the
{file:HAML_REFERENCE.md#encoding-option `:encoding` option} is not set.
Rather than defaulting to `"utf-8"`,
it defaults to the encoding of the source document,
and only falls back to `"utf-8"` if this encoding is `"us-ascii"`.

The `haml` executable also now takes an `-E` option for specifying encoding,
which works the same way as Ruby's `-E` option.

### Other Changes

* Default to the {file:HAML_REFERENCE.md#format-option `:html5` format}
  when running under Rails 3,
  since it defaults to HTML5 as well.

### Bug Fixes

* When generating Haml for something like `<span>foo</span>,`,
  use `= succeed` rather than `- succeed` (which doesn't work).

## 3.0.6

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.6).

### Rails 2.3.7 Support

This release fully supports Rails 2.3.7.

### Rails 2.3.6 Support Removed

Rails 2.3.6 was released with various bugs related to XSS-protection
and interfacing with Haml.
Rails 2.3.7 was released shortly after with fixes for these bugs.
Thus, Haml no longer supports Rails 2.3.6,
and anyone using it should upgrade to 2.3.7.

Attempting to use Haml with Rails 2.3.6 will cause an error.

## 3.0.5

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.5).

### Rails 2.3.6 Support

This release hacks around various bugs in Rails 2.3.6,
bringing Haml up to full compatibility.

### Rails 3 Support

Make sure the `#capture` helper in Rails 3
doesn't print its value directly to the template.

## 3.0.4

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.4).

There were no changes made to Haml between versions 3.0.3 and 3.0.4.

## 3.0.3

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.3).

### Rails 3 Support

In order to make some Rails loading errors easier to debug,
Sass will now raise an error if `Rails.root` is `nil` when Sass is loading.
Previously, this would just cause the paths to be mis-set.

## 3.0.2

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.2).

There were no changes made to Haml between versions 3.0.1 and 3.0.2.

## 3.0.1

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.1).

### Installation in Rails

`haml --rails` is no longer necessary for installing Haml in Rails.
Now all you need to do is add `gem "haml"` to the Gemfile for Rails 3,
or add `config.gem "haml"` to `config/environment.rb` for previous versions.

`haml --rails` will still work,
but it has been deprecated and will print an error message.
It will not work in the next version of Haml.

### Rails Test Speed

The {file:HAML_REFERENCE.md#ugly-option `:ugly` option} is now on by default
in the testing environment in Rails to help tests run faster.

## 3.0.0

[Tagged on GitHub](http://github.com/nex3/haml/commit/3.0.0).

### Backwards Incompatibilities: Must Read!

* The `puts` helper has been removed.
  Use {Haml::Helpers#haml\_concat} instead.

### More Useful Multiline

Ruby code can now be wrapped across multiple lines
as long as each line but the last ends in a comma.
For example:

    = link_to_remote "Add to cart",
        :url => { :action => "add", :id => product.id },
        :update => { :success => "cart", :failure => "error" }

### `haml_tag` and `haml_concat` Improvements

#### `haml_tag` with CSS Selectors

The {Haml::Helpers#haml_tag haml\_tag} helper can now take a string
using the same class/id shorthand as in standard Haml code.
Manually-specified class and id attributes are merged,
again as in standard Haml code.
For example:

    haml_tag('#foo') #=> <div id='foo' />
    haml_tag('.bar') #=> <div class='bar' />
    haml_tag('span#foo.bar') #=> <span class='bar' id='foo' />
    haml_tag('span#foo.bar', :class => 'abc') #=> <span class='abc bar' id='foo' />
    haml_tag('span#foo.bar', :id => 'abc') #=> <span class='bar' id='abc_foo' />

Cheers, [S. Burkhard](http://github.com/hasclass/).

#### `haml_tag` with Multiple Lines of Content

The {Haml::Helpers#haml_tag haml\_tag} helper also does a better job
of formatting tags with multiple lines of content.
If a tag has multiple levels of content,
that content is indented beneath the tag.
For example:

    haml_tag(:p, "foo\nbar") #=>
      # <p>
      #   foo
      #   bar
      # </p>

#### `haml_tag` with Multiple Lines of Content

Similarly, the {Haml::Helpers#haml_concat haml\_concat} helper
will properly indent multiple lines of content.
For example:

    haml_tag(:p) {haml_concat "foo\nbar"} #=>
      # <p>
      #   foo
      #   bar
      # </p>

#### `haml_tag` and `haml_concat` with `:ugly`

When the {file:HAML_REFERENCE.md#ugly-option `:ugly` option} is enabled,
{Haml::Helpers#haml_tag haml\_tag} and {Haml::Helpers#haml_concat haml\_concat}
won't do any indentation of their arguments.

### Basic Tag Improvements

* It's now possible to customize the name used for {file:HAML_REFERENCE.md#object_reference_ object reference}
  for a given object by implementing the `haml_object_ref` method on that object.
  This method should return a string that will be used in place of the class name of the object
  in the generated class and id.
  Thanks to [Tim Carey-Smith](http://twitter.com/halorgium).

* All attribute values may be non-String types.
  Their `#to_s` method will be called to convert them to strings.
  Previously, this only worked for attributes other than `class`.

### `:class` and `:id` Attributes Accept Ruby Arrays

In an attribute hash, the `:class` attribute now accepts an Array
whose elements will be converted to strings and joined with <nobr>`" "`</nobr>.
Likewise, the `:id` attribute now accepts an Array
whose elements will be converted to strings and joined with `"_"`.
The array will first be flattened and any elements that do not test as true
will be stripped out. For example:

    .column{:class => [@item.type, @item == @sortcol && [:sort, @sortdir]] }

could render as any of:

    class="column numeric sort ascending"
    class="column numeric"
    class="column sort descending"
    class="column"

depending on whether `@item.type` is `"numeric"` or `nil`,
whether `@item == @sortcol`,
and whether `@sortdir` is `"ascending"` or `"descending"`.

A single value can still be specified.
If that value evaluates to false it is ignored;
otherwise it gets converted to a string.
For example:

    .item{:class => @item.is_empty? && "empty"}

could render as either of:

    class="item"
    class="item empty"

Thanks to [Ronen Barzel](http://www.ronenbarzel.org/).

### HTML5 Custom Data Attributes

Creating an attribute named `:data` with a Hash value
will generate [HTML5 custom data attributes](http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data).
For example:

    %div{:data => {:author_id => 123, :post_id => 234}}

Will compile to:

    <div data-author_id='123' data-post_id='234'></div>

Thanks to [John Reilly](http://twitter.com/johnreilly).

### More Powerful `:autoclose` Option

The {file:HAML_REFERENCE.md#attributes_option `:attributes`} option
can now take regular expressions that specify which tags to make self-closing.

### `--double-quote-attributes` Option

The Haml executable now has a `--double-quote-attributes` option (short form: `-q`)
that causes attributes to use a double-quote mark rather than single-quote.
Thanks to [Charles Roper](http://charlesroper.com/).

### `:css` Filter

Haml now supports a {file:HAML_REFERENCE.md#css-filter `:css` filter}
that surrounds the filtered text with `<style>` and CDATA tags.

### `haml-spec` Integration

We've added the cross-implementation tests from the [haml-spec](http://github.com/norman/haml-spec) project
to the standard Haml test suite, to be sure we remain compatible with the base functionality
of the many and varied [Haml implementations](http://en.wikipedia.org/wiki/Haml#Implementations).

### Ruby 1.9 Support

* Haml and `html2haml` now produce more descriptive errors
  when given a template with invalid byte sequences for that template's encoding,
  including the line number and the offending character.

* Haml and `html2haml` now accept Unicode documents with a
  [byte-order-mark](http://en.wikipedia.org/wiki/Byte_order_mark).

### Rails Support

* When `form_for` is used with `=`, or `form_tag` is used with `=` and a block,
  they will now raise errors explaining that they should be used with `-`.
  This is similar to how {Haml::Helpers#haml\_concat} behaves,
  and will hopefully clear up some difficult bugs for some users.

### Rip Support

Haml is now compatible with the [Rip](http://hellorip.com/) package management system.
Thanks to [Josh Peek](http://joshpeek.com/).

### `html2haml` Improvements

* Ruby blocks within ERB are now supported.
  The Haml code is properly indented and the `end`s are removed.
  This includes methods with blocks and all language constructs
  such as `if`, `begin`, and `case`.
  For example:

      <% content_for :footer do %>
        <p>Hi there!</p>
      <% end %>

  is now transformed into:

      - content_for :footer do
        %p Hi there!

  Thanks to [Jack Chen](http://chendo.net) and [Dr. Nic Williams](http://drnicwilliams)
  for inspiring this and creating the first draft of the code.

* Inline HTML text nodes are now transformed into inline Haml text.
  For example, `<p>foo</p>` now becomes `%p foo`, whereas before it became:

      %p
        foo

  The same is true for inline comments,
  and inline ERB when running in ERB mode:
  `<p><%= foo %></p>` will now become `%p= foo`.

* ERB included within text is now transformed into Ruby interpolation.
  For example:

      <p>
        Foo <%= bar %> baz!
        Flip <%= bang %>.
      </p>

  is now transformed into:

      %p
        Foo #{bar} baz!
        Flip #{bang}.

* `<script>` tags are now transformed into `:javascript` filters,
  and `<style>` tags into `:css` filters.
  and indentation is preserved.
  For example:

      <script type="text/javascript">
        function foo() {
          return 12;
        }
      </script>

  is now transformed into:

      :javascript
        function foo() {
          return 12;
        }

* `<pre>` and `<textarea>` tags are now transformed into the `:preserve` filter.
  For example:

      <pre>Foo
        bar
          baz</pre>

  is now transformed into:

      %pre
        :preserve
          Foo
            bar
              baz

* Self-closing tags (such as `<br />`) are now transformed into
  self-closing Haml tags (like `%br/`).

* IE conditional comments are now properly parsed.

* Attributes are now output in a more-standard format,
  without spaces within the curly braces
  (e.g. `%p{:foo => "bar"}` as opposed to `%p{ :foo => "bar" }`).

* IDs and classes containing `#` and `.` are now output as string attributes
  (e.g. `%p{:class => "foo.bar"}`).

* Attributes are now sorted, to maintain a deterministic order.

* `>` or {Haml::Helpers#succeed #succeed} are inserted where necessary
  when inline formatting is used.

* Multi-line ERB statements are now properly indented,
  and those without any content are removed.

### Minor Improvements

* {Haml::Helpers#capture_haml capture\_haml} is now faster when using `:ugly`.
  Thanks to [Alf Mikula](http://alfmikula.blogspot.com/).

* Add an `RDFa` doctype shortcut.

## 2.2.24

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.24).

* Don't prevent ActiveModel form elements from having error formatting applied.

* Make sure `form_for` blocks are properly indented under Rails 3.0.0.beta.3.

* Don't activate a bug in the `dynamic_form` plugin under Rails 3.0.0.beta.3
  that would cause its methods not to be loaded.

## 2.2.23

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.23).

* Don't crash when `rake gems` is run in Rails with Haml installed.
  Thanks to [Florian Frank](http://github.com/flori).

* Don't remove `\n` in filters with interpolation.

* Silence those annoying `"regexp match /.../n against to UTF-8 string"` warnings.

## 2.2.22

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.22).

* Add a railtie so Haml and Sass will be automatically loaded in Rails 3.
  Thanks to [Daniel Neighman](http://pancakestacks.wordpress.com/).

* Add a deprecation message for using `-` with methods like `form_for`
  that return strings in Rails 3.
  This is [the same deprecation that exists in Rails 3](http://github.com/rails/rails/commit/9de83050d3a4b260d4aeb5d09ec4eb64f913ba64).

* Make sure line numbers are reported correctly when filters are being used.

* Make loading the gemspec not crash on read-only filesystems like Heroku's.

* Don't crash when methods like `form_for` return `nil` in, for example, Rails 3 beta.

* Compatibility with Rails 3 beta's RJS facilities.

## 2.2.21

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.21).

* Fix a few bugs in the git-revision-reporting in Haml::Version.
  In particular, it will still work if `git gc` has been called recently,
  or if various files are missing.

* Always use `__FILE__` when reading files within the Haml repo in the `Rakefile`.
  According to [this bug report](http://github.com/carlhuda/bundler/issues/issue/44),
  this should make Haml work better with Bundler.

* Make the error message for `- end` a little more intuitive based on user feedback.

* Compatibility with methods like `form_for`
  that return strings rather than concatenate to the template in Rails 3.

* Add a {Haml::Helpers#with_tabs with_tabs} helper,
  which sets the indentation level for the duration of a block.

## 2.2.20

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.20).

* The `form_tag` Rails helper is now properly marked as HTML-safe
  when using Rails' XSS protection with Rails 2.3.5.

* Calls to `defined?` shouldn't interfere with Rails' autoloading
  in very old versions (1.2.x).

* Fix a bug where calls to ActionView's `render` method
  with blocks and layouts wouldn't work under the Rails 3.0 beta.

* Fix a bug where the closing tags of nested calls to \{Haml::Helpers#haml\_concat}
  were improperly escaped under the Rails 3.0 beta.

## 2.2.19

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.19).

* Fix a bug with the integration with Rails' XSS support.
  In particular, correctly override `safe_concat`.

## 2.2.18

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.18).

* Support [the new XSS-protection API](http://yehudakatz.com/2010/02/01/safebuffers-and-rails-3-0/)
  used in Rails 3.

* Use `Rails.env` rather than `RAILS_ENV` when running under Rails 3.0.
  Thanks to [Duncan Grazier](http://duncangrazier.com/).

* Add a `--unix-newlines` flag to all executables
  for outputting Unix-style newlines on Windows.

* Fix a couple bugs with the `:erb` filter:
  make sure error reporting uses the correct line numbers,
  and allow multi-line expressions.

* Fix a parsing bug for HTML-style attributes including `#`.

## 2.2.17

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.17).

* Fix compilation of HTML5 doctypes when using `html2haml`.

* `nil` values for Sass options are now ignored,
  rather than raising errors.

## 2.2.16

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.16).

* Abstract out references to `ActionView::TemplateError`,
  `ActionView::TemplateHandler`, etc.
  These have all been renamed to `ActionView::Template::*`
  in Rails 3.0.

## 2.2.15

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.15).

* Allow `if` statements with no content followed by `else` clauses.
  For example:

    - if foo
    - else
      bar

## 2.2.14

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.14).

* Don't print warnings when escaping attributes containing non-ASCII characters
  in Ruby 1.9.

* Don't crash when parsing an XHTML Strict doctype in `html2haml`.

* Support the  HTML5 doctype in an XHTML document
  by using `!!! 5` as the doctype declaration.

## 2.2.13

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.13).

* Allow users to specify {file:HAML_REFERENCE.md#encoding_option `:encoding => "ascii-8bit"`}
  even for templates that include non-ASCII byte sequences.
  This makes Haml templates not crash when given non-ASCII input
  that's marked as having an ASCII encoding.

* Fixed an incompatibility with Hpricot 0.8.2, which is used for `html2haml`.

## 2.2.12

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.12).

There were no changes made to Haml between versions 2.2.11 and 2.2.12.

## 2.2.11

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.11).

* Fixed a bug with XSS protection where HTML escaping would raise an error
  if passed a non-string value.
  Note that this doesn't affect any HTML escaping when XSS protection is disabled.

* Fixed a bug in outer-whitespace nuking where whitespace-only Ruby strings
  blocked whitespace nuking beyond them.

* Use `ensure` to protect the resetting of the Haml output buffer
  against exceptions that are raised within the compiled Haml code.

* Fix an error line-numbering bug that appeared if an error was thrown
  within loud script (`=`).
  This is not the best solution, as it disables a few optimizations,
  but it shouldn't have too much effect and the optimizations
  will hopefully be re-enabled in version 2.4.

* Don't crash if the plugin skeleton is installed and `rake gems:install` is run.

* Don't use `RAILS_ROOT` directly.
  This no longer exists in Rails 3.0.
  Instead abstract this out as `Haml::Util.rails_root`.
  This changes makes Haml fully compatible with edge Rails as of this writing.

## 2.2.10

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.10).

* Fixed a bug where elements with dynamic attributes and no content
  would have too much whitespace between the opening and closing tag.

* Changed `rails/init.rb` away from loading `init.rb` and instead
  have it basically copy the content.
  This allows us to transfer the proper binding to `Haml.init_rails`.

* Make sure Haml only tries to enable XSS protection integration
  once all other plugins are loaded.
  This allows it to work properly when Haml is a gem
  and the `rails_xss` plugin is being used.

* Mark the return value of Haml templates as HTML safe.
  This makes Haml partials work with Rails' XSS protection.

## 2.2.9

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.9).

* Fixed a bug where Haml's text was concatenated to the wrong buffer
  under certain circumstances.
  This was mostly an issue under Rails when using methods like `capture`.

* Fixed a bug where template text was escaped when there was interpolation in a line
  and the `:escape_html` option was enabled. For example:

      Foo &lt; Bar #{"<"} Baz

  with `:escape_html` used to render as

      Foo &amp;lt; Bar &lt; Baz

  but now renders as

      Foo &lt; Bar &lt; Baz

### Rails XSS Protection

Haml 2.2.9 supports the XSS protection in Rails versions 2.3.5+.
There are several components to this:

* If XSS protection is enabled, Haml's {file:HAML_REFERENCE.md#escape_html-option `:escape_html`}
  option is set to `true` by default.

* Strings declared as HTML safe won't be escaped by Haml,
  including the {file:Haml/Helpers.html#html_escape-instance_method `#html_escape`} helper
  and `&=` if `:escape_html` has been disabled.

* Haml helpers that generate HTML are marked as HTML safe,
  and will escape their input if it's not HTML safe.

## 2.2.8

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.8).

* Fixed a potential XSS issue with HTML escaping and wacky Unicode nonsense.
  This is the same as [the issue fixed in Rails](http://groups.google.com/group/rubyonrails-security/browse_thread/thread/48ab3f4a2c16190f) a bit ago.

## 2.2.7

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.7).

* Fixed an `html2haml` issue where ERB attribute values
  weren't HTML-unescaped before being transformed into Haml.

* Fixed an `html2haml` issue where `#{}` wasn't escaped
  before being transformed into Haml.

* Add `<code>` to the list of tags that's
  {file:HAML_REFERENCE.md#preserve-option automatically whitespace-preserved}.

* Fixed a bug with `end` being followed by code in silent scripts -
  it no longer throws an error when it's nested beneath tags.

* Fixed a bug with inner whitespace-nuking and conditionals.
  The `else` et al. clauses of conditionals are now properly
  whitespace-nuked.

## 2.2.6

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.6).

* Made the error message when unable to load a dependency for html2haml
  respect the `--trace` option.

* Don't crash when the `__FILE__` constant of a Ruby file is a relative path,
  as apparently happens sometimes in TextMate
  (thanks to [Karl Varga](http://github.com/kjvarga)).

* Add "Sass" to the `--version` string for the executables.

* Raise an exception when commas are omitted in static attributes
  (e.g. `%p{:foo => "bar" :baz => "bang"}`).

## 2.2.5

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.5).

* Got rid of trailing whitespace produced when opening a conditional comment
  (thanks to [Norman Clarke](http://blog.njclarke.com/)).

* Fixed CSS id concatenation when a numeric id is given as an attribute.
  (thanks to [Norman Clarke](http://blog.njclarke.com/)).

* Fixed a couple bugs with using "-end" in strings.

## 2.2.4

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.4).

* Allow `end` to be used for silent script when it's followed by code.
  For example:

      - form_for do
        ...
      - end if @show_form

  This isn't very good style, but we're supporting it for consistency's sake.

* Don't add `require 'rubygems'` to the top of init.rb when installed
  via `haml --rails`. This isn't necessary, and actually gets
  clobbered as soon as haml/template is loaded.

## 2.2.3

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.3).

Haml 2.2.3 adds support for the JRuby bundling tools
for Google AppEngine, thanks to [Jan Ulbrich](http://github.com/ulbrich).

## 2.2.2

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.2).

Haml 2.2.2 is a minor bugfix release, with several notable changes.
First, {file:Haml/Helpers.html#haml_concat-instance_method `haml_concat`}
will now raise an error when used with `=`.
This has always been incorrect behavior,
and in fact has never actually worked.
The only difference is that now it will fail loudly.
Second, Ruby 1.9 is now more fully supported,
especially with the {file:HAML_REFERENCE.md#htmlstyle_attributes_ new attribute syntax}.
Third, filters are no longer escaped when the {file:HAML_REFERENCE.md#escape_html-option `:escape_html` option}
is enabled and `#{}` interpolation is used.

## 2.2.1

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.1).

Haml 2.2.1 is a minor bug-fix release.

## 2.2.0

[Tagged on GitHub](http://github.com/nex3/haml/commit/2.2.0).

Haml 2.2 adds several new features to the language,
fixes several bugs, and dramatically improves performance
(particularly when running with {file:HAML_REFERENCE.md#ugly-option `:ugly`} enabled).

### Syntax Changes

#### HTML-Style Attribute Syntax

Haml 2.2 introduces a new syntax for attributes
based on the HTML syntax.
For example:

    %a(href="http://haml.info" title="Haml's so cool!")
      %img(src="/images/haml.png" alt="Haml")

There are two main reasons for this.
First, the hash-style syntax is very Ruby-specific.
There are now [Haml implementations](http://en.wikipedia.org/wiki/Haml#Implementations)
in many languages, each of which has its own syntax for hashes
(or dicts or associative arrays or whatever they're called).
The HTML syntax will be adopted by all of them,
so you can feel comfortable using Haml in whichever language you need.

Second, the hash-style syntax is quite verbose.
`%img{:src => "/images/haml.png", :alt => "Haml"}`
is eight characters longer than `%img(src="/images/haml.png" alt="Haml")`.
Haml's supposed to be about writing templates quickly and easily;
HTML-style attributes should help out a lot with that.

Ruby variables can be used as attribute values by omitting quotes.
Local variables or instance variables can be used.
For example:

    %a(title=@title href=href) Stuff

This is the same as:

    %a{:title => @title, :href => href} Stuff

Because there are no commas separating attributes,
more complicated expressions aren't allowed.
You can use `#{}` interpolation to insert complicated expressions
in a HTML-style attribute, though:

    %span(class="widget_#{@widget.number}")

#### Multiline Attributes

In general, Haml tries to keep individual elements on a single line.
There is a [multiline syntax](#multiline) for overflowing onto further lines,
but it's intentionally awkward to use to encourage shorter lines.

However, there is one case where overflow is reasonable: attributes.
Often a tag will simply have a lot of attributes, and in this case
it makes sense to allow overflow.
You can now stretch an attribute hash across multiple lines:

    %script{:type => "text/javascript",
            :src  => "javascripts/script_#{2 + 7}"}

This also works for HTML-style attributes:

        %script(type="text/javascript"
            src="javascripts/script_#{2 + 7}")

Note that for hash-style attributes, the newlines must come after commas.

#### Universal interpolation

In Haml 2.0, you could use `==` to interpolate Ruby code
within a line of text using `#{}`.
In Haml 2.2, the `==` is unnecessary;
`#{}` can be used in any text.
For example:

    %p This is a really cool #{h what_is_this}!
    But is it a #{h what_isnt_this}?

In addition, to {file:HAML_REFERENCE.md#escaping_html escape} or {file:HAML_REFERENCE.md#unescaping_html unescape}
the interpolated code, you can just add `&` or `!`, respectively,
to the beginning of the line:

    %p& This is a really cool #{what_is_this}!
    & But is it a #{what_isnt_this}?

#### Flexible indentation

Haml has traditionally required its users to use two spaces of indentation.
This is the universal Ruby style, and still highly recommended.
However, Haml now allows any number of spaces or even tabs for indentation,
provided:

* Tabs and spaces are not mixed
* The indentation is consistent within a given document

### New Options

#### `:ugly`

The `:ugly` option is not technically new;
it was introduced in Haml 2.0 to make rendering deeply nested templates less painful.
However, it's been greatly empowered in Haml 2.2.
It now does all sorts of performance optimizations
that couldn't be done before,
and its use increases Haml's performance dramatically.
It's enabled by default in production in Rails,
and it's highly recommended for production environments
in other frameworks.

#### `:encoding` {#encoding-option}

This option specifies the encoding of the Haml template
when running under Ruby 1.9. It defaults to `Encoding.default_internal` or `"utf-8"`.
This is useful for making sure that you don't get weird
encoding errors when dealing with non-ASCII input data.

### Deprecations

#### `Haml::Helpers#puts`

This helper is being deprecated for the obvious reason
that it conflicts with the `Kernel#puts` method.
I'm ashamed I ever chose this name.
Use `haml_concat` instead and spare me the embarrassment.

#### `= haml_tag`

A lot of people accidentally use "`= haml_tag`".
This has always been wrong; `haml_tag` outputs directly to the template,
and so should be used as "`- haml_tag`".
Now it raises an error when you use `=`.

### Compatibility

#### Rails

Haml 2.2 is fully compatible with Rails,
from 2.0.6 to the latest revision of edge, 783db25.

#### Ruby 1.9

Haml 2.2 is also fully compatible with Ruby 1.9.
It supports Ruby 1.9-style attribute hashes,
and handles encoding-related issues
(see [the `:encoding` option](#encoding-option)).

### Filters

#### `:markdown`

There are numerous improvements to the Markdown filter.
No longer will Haml attempt to use RedCloth's inferior Markdown implementation.
Instead, it will look for all major Markdown implementations:
[RDiscount](https://github.com/rtomayko/rdiscount),
[RPeg-Markdown](https://github.com/rtomayko/rpeg-markdown),
[Maruku](http://maruku.rubyforge.org),
and [BlueCloth](http://www.deveiate.org/projects/BlueCloth).

#### `:cdata`

There is now a `:cdata` filter for wrapping text in CDATA tags.

#### `:sass`

The `:sass` filter now uses options set in `Sass::Plugin`,
if they're available.

### Executables

#### `haml`

The `haml` executable now takes `-r` and `-I` flags
that act just like the same flags for the `ruby` executable.
This allows users to load helper files when using Haml
from the command line.

It also takes a `--debug` flag that causes it to spit out
the Ruby code that Haml generates from the template.
This is more for my benefit than anything,
but you may find it interesting.

#### `html2haml`

The `html2haml` executable has undergone significant improvements.
Many of these are bugfixes, but there are also a few features.
For one, it now understands CDATA tags and autodetects ERB files.
In addition, a line containing just "`- end`" is now a Haml error;
since it's not possible for `html2haml` to properly parse all Ruby blocks,
this acts as a signal for the author that there are blocks
to be dealt with.

### Miscellaneous

#### XHTML Mobile DTD

Haml 2.2 supports a DTD for XHTML Mobile: `!!! Mobile`.

#### YARD

All the documentation for Haml 2.2, including this changelog,
has been moved to [YARD](http://yard.soen.ca).
YARD is an excellent documentation system,
and allows us to write our documentation in [Maruku](http://maruku.rubyforge.org),
which is also excellent.
