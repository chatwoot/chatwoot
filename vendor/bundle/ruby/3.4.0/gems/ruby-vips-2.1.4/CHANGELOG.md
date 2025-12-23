# Changelog

## master

## Version 2.1.4 (2021-10-28)

* `write_to_buffer` tries to use the new target API, then falls back to the old 
  buffer system [jcupitt]
* don't generate yard docs for deprecated args [jcupitt]
* add hyperbolic trig functions [jcupitt]

## Version 2.1.3 (2021-8-23)

* fix a gtype size error on win64 [danini-the-panini]

## Version 2.1.2 (2021-5-3)

* allow `FFI::Pointer` as an argument to `new_from_memory` etc. [sled]

## Version 2.1.1 (2021-5-3)

* fix "mutate" with libvips 8.9 [jcupitt]
* update autodocs for libvips 8.11 [jcupitt]

## Version 2.1.0 (2021-3-8)

* add "mutate" system [jcupitt]
* better behaviour with some nil parameters [jcupitt]
* revise gemspec [jcupitt]
* allow symbols for Interpolate.new [noraj]
* update docs for 8.10, fix minor doc formatting issues [jcupitt]
* `new_from_array` checks array argument more carefully [dkam]
* add `new_from_memory` and `new_from_memory_copy` [ankane]
* jruby added to CI testing [pftg]
* switch to github actions for CI [pftg]
* remove rubocop, revise formatting for standardrb [pftg]

## Version 2.0.17 (2019-10-29)

* install msys2 libvips on Windows [larskanis]
* better `-` to `_` conversion [Nakilon]
* fix `GValue#set` for stricter metadata rules in 8.9 [jcupitt]
* fix a ref leak on operation build error [jcupitt]
* faster operation call [jcupitt]
* add support for VipsConnection [jcupitt]
* add `signal_connect` [jcupitt]
* add `Image#set_kill` for progress termination [jcupitt]

## Version 2.0.16 (2019-9-21)

* better library name generation [renchap]
* allow `_` as a separator in enum names [D-W-L]
* add `Vips::Region` and `Region#fetch` [jcupitt]

## Version 2.0.15 (2019-6-12)

* better error messages from `write_to_memory` [linkyndy]
* fix doc generation typo for array return [jcupitt]
* update tests for libvips 8.8 [jcupitt]

## Version 2.0.14 (2018-10-3)

* update links for new home [jcupitt]
* various doc fixes [janko-m]
* add `Vips::get_suffixes` [jcupitt]
* prefer options splat [ioquatix]
* update docs for 8.8 [jcupitt]

## Version 2.0.13 (2018-8-6)

* allow optional args to have `nil` as a value [janko-m]
* fix five small memleaks [kleisauke]

## Version 2.0.12 (2018-4-25)

* fix `Vips::Image#has_alpha?` with older libvips [larskanis]

## Version 2.0.11 (2018-4-23)

* fix init with older glib [lsat12357]
* add `Vips::Image#has_alpha?` and `#add_alpha` [aried3r]

## Version 2.0.10 (2017-12-21)

* add support for uint64 parameters
* add `draw_point` convenience method
* add docs for `CompassDirection` [janko-m]
* add `MAX_COORD` constant
* doc fixes [janko-m]
* remove duplicate function attach [janko-m]
* fix a crash with `new_from_buffer` with a UTF-8 string [janko-m]

## Version 2.0.9 (2017-12-21)

* update docs for libvips 8.6

## Version 2.0.8 (2017-09-14)

* add `thumb.rb` example, and verify we run stably and in constant memory 
* cleanups and polish [Nakilon]
* add `composite` convenience method 
* add `Vips::concurrency_set` and `Vips::vector_set`

## Version 2.0.7 (2017-09-08)

* disable the logging for now, it could deadlock

## Version 2.0.6 (2017-09-02)

* improve get() behaviour on error with older libvipses

## Version 2.0.5 (2017-09-02)

* fix get() with older libvipses

## Version 2.0.4 (2017-09-02)

* add a test for `get_fields`, since it appeared in libvips 8.5 (thanks zverok)

## Version 2.0.3 (2017-09-02)

* add `get_fields`

## Version 2.0.2 (2017-08-26)

* switch to `logger` for all logging output
* add libvips cache control functions `Vips::cache_set_max()` etc.
* fix a ref leak

## Version 2.0.1 (2017-08-23)

* add support for `VipsRefStr` in gvalue, thanks tomasc

## Version 2.0.0 (2017-08-22)

* rewrite on top of 'ffi' [John Cupitt, Kleis Auke Wolthuizen]

## Version 1.0.6 (2017-07-17)

* remove lazy load, fixing a race with multi-threading [felixbuenemann]
* make `Image#to_a` much faster [John Cupitt]
* remove the `at_exit` handler [John Cupitt]

## Version 1.0.5 (2017-04-29)

* fix `_const` for libvips 8.5 [John Cupitt]
* add `scaleimage`, the scale operation renamed to avoid a clash with the
  `scale` property [John Cupitt]
* add `.new_from_image`: make a new image from a constant [John Cupitt]
* `bandjoin` will use `bandjoin_const`, if it can [John Cupitt]
* update generated docs for libvips 8.5 [John Cupitt]
* added docs for new libvips 8.5 enums [John Cupitt]

## Version 1.0.4 (2017-02-07)

* remove stray comma from some docs lines [John Cupitt]
* update generated docs for libvips 8.5 [John Cupitt]
* small doc improvements [John Cupitt]
* update for gobject-introspection 3.1 [John Cupitt]
* support ruby 2.4 [John Cupitt]

## Version 1.0.3 (2016-08-18)

* doc improvements [John Cupitt]
* add `Image#size` to get `[width, height]` [John Cupitt]
* only ask for ruby 2.0 to help OS X [John Cupitt]
* break up `Image.call` to make it easier to understand [John Cupitt]
* detect operation build fail correctly [John Cupitt]
* lock gobject-introspection at 3.0.8 to avoid breakage [John Cupitt]

## Version 1.0.2 (2016-07-07)

* add `.yardopts` to fix ruby-gems docs [John Cupitt]

## Version 1.0.1 (2016-07-07)

* simplify gemspec [sandstrom]
* remove jeweler dependency [John Cupitt]
* add `.to_a` to Image [John Cupitt]

## Version 1.0.0 (2016-06-07)

* complete rewrite, API break [John Cupitt]

## Version 0.3.14 (2016-01-25)

* more GC tuning [felixbuenemann]
* add `write.rb` example program [felixbuenemann]

## Version 0.3.13 (2016-01-18)

* don't use generational GC options on old Rubys [John Cupitt]

## Version 0.3.12 (2016-01-17)

* incremental GC every 10 writes [felixbuenemann]
* updated bundle [John Cupitt]

## Version 0.3.11 (2015-10-15)

* added magick load from buffer [John Cupitt]

## Version 0.3.10 (2015-06-24)

* added webp write [John Cupitt]

## Version 0.3.9 (2014-07-17)

* removed a stray file from gemspec [Alessandro Tagliapietra]
* updated bundle [John Cupitt]
* revised spec tests [John Cupitt]
* fix a segv in im.label_regions [John Cupitt]
* add a Valgrind suppressions file [John Cupitt]
* fix .monotonic? [John Cupitt]
* fix .data on coded images [John Cupitt]
* add .size, see issue #58 [John Cupitt]
* add rdoc-data dep, maybe it will help ruby-gems docs [John Cupitt]

## Version 0.3.8 (2014-05-11)

* add VIPS::thread_shutdown(), must be called on foreign thread exit [John Cupitt]

## Version 0.3.7 (2014-02-04)

* update build dependencies [John Cupitt]
* README updated [John Cupitt]

## Version 0.3.6 (2013-06-25)

* add png and jpg load from memory buffer [John Cupitt]
* README updated to include buffer read/write example [John Cupitt]
* better vips version testing [John Cupitt]
* spec tests for new buffer read/write code [John Cupitt]
* fix rdoc build to include C sources [John Cupitt]
* better compat with older libvips [John Cupitt]

## Version 0.3.5 (2013-01-15)

* rb_raise() in mask.c no longer passes a string pointer as the fmt arg, stopping gcc bailing out on some platforms [John Cupitt]
* Image.magick() now calls im_magick2vips() directly rather than relying on libvips file type sniffing [John Cupitt]

## Version 0.3.4 (2012-09-11)

* Update specs for lcms changes, thanks Stanislaw [John Cupitt]
* VIPS::Reader supports .exif() / .exif?() methods for better back compat, thanks Jeremy [John Cupitt]
* VIPS::Reader fallbacks load the image if its not been loaded [John Cupitt]
* VIPS::Reader no longer allows VIPS::Header methods [John Cupitt]

## Version 0.3.3 (2012-08-31)

* Typo in workaround in 0.3.2 [John Cupitt]

## Version 0.3.2 (2012-08-31)

### Fixed

* Workaround helps ruby-vips compile (and run) against 7.26.3 [John Cupitt and 
James Harrison]

## Version 0.3.1 (2012-08-30)

### Fixed

* PNG writer no longer changes the filename argument [John Cupitt]
* Workaround helps ruby-vips compile against 7.26.3 [John Cupitt]
* Image read now runs GC and retries on fail [John Cupitt]
* Image write GCs every 100 images [John Cupitt]

## Version 0.3.0 (2012-07-20)

### Added

* More rspec tests [John Cupitt]
* Updated to libvips-7.30 [John Cupitt]

### Changed

* Reworked Reader class offers better performance and compatibility [John
  Cupitt]
* Don't use :sequential option for older libvipses [John Cupitt]
* Rename "tone_analyze" as "tone_analyse" for consistency with the rest of
  vips [John  CUpitt]

### Fixed

* Now passes rspec test suite cleanly in valgrind [John Cupitt]
* Fixed check of sequential mode support [Stanislaw Pankevich]

## Version 0.2.0 (2012-06-29)

### Added

* Add tile_cache [John Cupitt]
* Add :sequential option to tiff, jpeg and png readers [John Cupitt]
* Add raise if suitable pkg_config for libvips is not found, thanks to Pierre
  Chapuis [Stanislaw Pankevich]
* Add backward compatibility of 0.1.x ruby-vips with libvips versions less than 7.28 [John Cupitt]
* Add Travis. ruby-vips now is being tested on travis-ci.org. [Stanislaw Pankevich]

### Changed

* Disable the vips8 operation cache to save some memory [John Cupitt]
* Update example shrinker [John Cupitt]

### Fixed

* #8: Memory allocation-free issues [Grigoriy Chudnov]

## Version 0.1.1 (2012-06-22)

### Changed

* Upgrade spec/* code to latest RSpec  [Stanislaw Pankevich]

### Added

* Added CHANGELOG.md file (thanks to jnicklas/capybara - using the layout of their History.txt) [Stanislaw Pankevich]
* Added Gemfile with the only 'rspec' dependency. [Stanislaw Pankevich]
* Added Jeweler Rakefile contents to release ruby-vips as a gem. [Stanislaw Pankevich]

## Before (initial unreleased version 0.1.0)

Long-long history here undocumented...
