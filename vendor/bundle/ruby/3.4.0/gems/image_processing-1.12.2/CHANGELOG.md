## 1.12.2 (2022-03-01)

* Prevent remote shell execution when using `#apply` with operations coming from user input (@janko)

## 1.12.1 (2020-11-06)

* Fix format fallback for files ending with a dot on Ruby 2.7+ (@coding-chimp)

## 1.12.0 (2020-09-20)

* Add instrumentation support via `#instrumenter` (@janko)

## 1.11.0 (2020-05-17)

* [minimagick] Handle destination format having no file extension (@janko)

* [minimagick] Disable sharpening on `#resize_*` operators by default (@flori)

* [minimagick] Add `#crop` which accepts `left, top, width, height` arguments (@janko)

## 1.10.3 (2020-01-12)

* [vips] Fix auto-rotation not working in certain cases on libvips 8.9.0 (@janko)

## 1.10.2 (2020-01-11)

* Fix Ruby 2.7 warnings for separation of positional and keyword arguments (@kamipo, @janko)

## 1.10.1 (2020-01-07)

* [vips] Fix compatibility with ruby-vips 2.0.17+ (@janko)

## 1.10.0 (2019-12-18)

* [minimagick] Add `:loader` option for explicitly setting input file type (@janko)

## 1.9.3 (2019-08-11)

* [vips] Use integer precision when sharpening for better quality (@metaskills)

## 1.9.2 (2019-07-22)

* Bump `mini_magick` dependency to `>= 4.9.5` (@chioreandan)

## 1.9.1 (2019-07-20)

* Bring back support for MRI 2.3 (@janko)

## 1.9.0 (2019-04-09)

* Drop support for MRI 2.2 and 2.3 (@janko)

* [vips] Allow forcing a specific loader or saver (@janko)

## 1.8.0 (2019-02-25)

* [vips] Perform resize-on-load when possible, significantly improving resizing speed (@janko)

## 1.7.1 (2018-09-27)

* [vips] Make `#remove` that's used for removing image metadata chainable (@janko)

## 1.7.0 (2018-09-20)

* [vips] `#rotate` now always calls `vips_similarity()` and forwards all options to it (@janko)

## 1.6.0 (2018-07-13)

* [vips] In `#composite` accept `:offset` option for the position of the overlay image (@janko)

* [vips] In `#composite` accept `:gravity` option for the direction of the overlay image (@janko)

* [vips] In `#composite` accept blend mode as an optional `:mode` parameter which defaults to `:over` (@janko)

* [minimagick] In `#composite` rename `:compose` option to `:mode` (@janko)

* [minimagick] In `#composite` replace `:geometry` option with `:offset` which accepts an array (@janko)

## 1.5.0 (2018-07-10)

* [minimagick, vips] Add `#composite` method (@janko)

* [core] Allow operations to accept blocks (janko-m)

## 1.4.0 (2018-06-14)

* [minimagick] Accept RGB(A) arrays for color names for `:background` (@janko)

* [minimagick] Don't add empty `-background` option in `#rotate` when `:background` is not given (@janko)

* [vips] Modify `#rotate` to accept only `:background` and not other `vips_similarity()` options (@janko)

## 1.3.0 (2018-06-13)

* [minimagick, vips] Add `#rotate` method (@janko)

* [vips] Use native `vips_image_hasalpha()` and `vips_addalpha()` functions in `#resize_and_pad` (@janko)

## 1.2.0 (2018-04-18)

* [minimagick] Allow appending "+" operators in `#loader` and `#saver` using the value `false` (@janko)

* [core] Fix `#apply` not accepting a Hash as an argument (@janko)

* [core] Allow sending any builder commands via `#apply`, not just operations (@janko)

* [minimagick] Add `#define` as a wrapper around `-define` (@janko)

## 1.1.0 (2018-04-05)

* [minimagick] Disallow splitting multi-layer images into multiple single-layer
  images by default to avoid unexpected behaviour, but can be re-enabled with
  the `:allow_splitting` saver option (@janko)

* [core] Add `#apply` for applying a list of operations (@janko)

## 1.0.0 (2018-04-04)

* Depend on `mini_magick` and `ruby-vips` gems (@janko, @mokolabs)

* [minimagick] Remove deprecated API in favor of the chainable API (@janko)

* [core] Rename `Builder#default_options` to `Builder#options` (@janko)

* [minimagick] Remove `:fail` loader option in favor of the existing `:regard_warnings` (@janko)

* [vips, minimagick] Don't fail on warnings when loading the image (@janko)

* [vips] Don't apply `Vips::Image#autorot` if `:autorotate` loader option was passed in (@janko)

* [minimagick] Allow using value `nil` to add ImageMagick options that don't have a value (@janko)

* [vips] Accept `:quality` saver option as an alias to `:Q` (@janko)

* [minimagick] Automatically sharpen thumbnails after resizing (@janko, @mokolabs)

* [vips] Automatically sharpen thumbnails after resizing (@janko, @mokolabs)

## 0.11.2 (2018-03-31)

* [minimagick] Avoid `#resize_*` operations stripping data by switching back to `-resize` (@janko)

* [core] Make sure an empty destination file doesn't remain on processing errors when `:destination` is used (@janko)

* [vips] Fix `:alpha` not correctly adding alpha for certain types of images (@janko)

## 0.11.1 (2018-03-27)

* [minimagick] Rename `#limit` to `#limits` to still allow adding `-limit` arguments directly (@janko)

## 0.11.0 (2018-03-27)

* [minimagick] Fix broken deprecated `#convert` (@janko)

* [minimagick] Add `#limit` for specifying resource limits using `-limit` (@janko)

* [minimagick] Use `-thumbnail` instead of `-resize` in `#resize_*` methods (@janko)

* [minimagick] Add loader and saver options (@janko)

## 0.10.3 (2018-03-24)

* [minimagick] Fix bang methods in deprecated API calling nondestructive versions (@janko)

## 0.10.2 (2018-03-22)

* [minimagick] Add back default offset arguments to deprecated `#crop` (@janko)

## 0.10.1 (2018-03-22)

* [minimagick] Don't print deprecation warning for old API twice when IO objects are used (@janko)

## 0.10.0 (2018-03-21)

* [minimagick] Rewrite MiniMagick module to use the chainable API (@janko)

* [minimagick] Deprecate the old API (@janko)

* [minimagick] Raise an exception on processing warnings (@janko)

* [minimagick] Speed up `.valid_image?` by an order of magnitude (@janko)

* [minimagick] Don't accept arbitrary IO object anymore (@janko)

* [minimagick] Removed unnecessary `#crop` and `#resample` macros (@janko)

* [vips] Ignore undefined loader/saver options (@janko)

* [vips] Preserve transparent background in `#resize_to_pad` (@janko)

* [vips] Remove the ability to specify colors using names (@janko)

* [minimagick, vips] Autorotate images after loading them (@janko)

* [core] Delete result `Tempfile` object in case of processing errors (@janko)

* [core] Allow returning `nil` in the `#custom` block (@janko)

* [core] Allow specifying a path string as source file (@janko)

* [core] Allow saving to a specific location with the `:destination` call option (@janko)

## 0.9.0 (2018-03-16)

* Added libvips module (@GustavoCaso, @janko)

* Drop official support for MRI 2.0 and 2.1

## 0.4.5 (2017-09-08)

* Add `lib/image_processing.rb` to allow loading via `Bundler.require` (@printercu)

## 0.4.4 (2017-06-16)

* Fix last changes being incompatible with older Ruby versions, again (@janko)

## 0.4.3 (2017-06-16)

* Fix last changes being incompatible with older Ruby versions (@janko)

## 0.4.2 (2017-06-16)

* Don't use path of input file as basename for output file (@janko)

## 0.4.1 (2016-09-08)

* Maintain transparent background of PNGs in `#resize_to_fill` (janko-m)

## 0.4.0 (2016-11-07)

* Add `#corrupted?` for checking whether an image is corrupted (janko-m)

## 0.3.0 (2016-05-03)

* Add cropping functionality to `ImageProcessing::MiniMagick` (paulgoetze)

## 0.2.5 (2016-03-24)

* Rewind the file after making a copy in non-destructive methods (janko-m)

* Add ability to supply page number to `#convert` (janko-m)

## 0.2.4 (2015-10-21)

* Don't error when checking MiniMagick version for older versions of MiniMagick (janko-m)

## 0.2.3 (2015-10-17)

* Fix uploading tempfiles to S3 using aws-sdk (janko-m)

* Make nondestructive methods available on class methods on `ImageProcessing::MiniMagick` (janko-m)

## 0.2.2 (2015-10-04)

* Make `ImageProcessing::MiniMagick#with_minimagick` public (janko-m)

* Add `ImageProcessing::MiniMagick#auto_orient` (janko-m)

## 0.2.1 (2015-10-03)

* Include the actual code in the gem (janko-m)

## 0.2.0 (2015-10-03)

* Add `ImageProcessing::MiniMagick#resample` for changing resolution (janko-m)

* Fix padding in `ImageProcessing::MiniMagick#resize_and_pad` (janko-m)
