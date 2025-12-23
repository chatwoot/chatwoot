# Rainbow changelog

## 3.1.0 (2020-08-26)

- added `cross_out` aka `strike`
- hexadecimal color names supported better, see #83
- gemspec: list files using a Ruby expression, avoiding git

## 3.0.0 (2017-11-29)

* added String refinement
* added new `Rainbow.uncolor` method
* dropped MRI 1.9.3 compatibility
* dropped MRI 2.0 compatibility
* removed Rake dependency

## 2.2.2 (2017-04-21)

* added explicit rake dependency to fix installation issue

## 2.2.1 (2016-12-28)

* fixed gem installation (2.2.0 was a broken release)

## 2.2.0 (2016-12-27)

* improved Windows support
* added Ruby 2.4 support
* added `bold` alias method for `bright`

## 2.1.0 (2016-01-24)

* added X11 color support
* fixed `require` issue when rainbow is used as a dependency in another gem
* improved Windows support

## 2.0.0 (2014-01-24)

* disable string mixin by default

## 1.99.2 (2014-01-24)

* bring back ruby 1.8 support

## 1.99.1 (2013-12-28)

* drop support for ruby 1.8
* `require "rainbow/string"` -> `require "rainbow/ext/string"`
* custom rainbow wrapper instances (with separate enabled/disabled state)
* shortcut methods for changing text color (`Rainbow("foo").red`)

## 1.99.0 (2013-12-26)

* preparation for dropping String monkey patching
* `require "rainbow/string"` if you want to use monkey patched String
* introduction of Rainbow() wrapper
* support for MRI 1.8.7, 1.9.2, 1.9.3, 2.0 and 2.1, JRuby and Rubinius
* deprecation of Sickill::Rainbow namespace (use Rainbow.enabled = true instead)

## 1.1.4 (2012-4-28)

* option for forcing coloring even when STDOUT is not a TTY (CLICOLOR_FORCE env var)
* fix for frozen strings

## 1.1.3 (2011-12-6)

* improved compatibility with MRI 1.8.7
* fix for regression with regards to original string mutation

## 1.1.2 (2011-11-13)

* improved compatibility with MRI 1.9.3

## 1.1.1 (2011-2-7)

* improved Windows support

## 1.1 (2010-6-7)

* option for enabling/disabling of escape code wrapping
* auto-disabling when STDOUT is not a TTY

## 1.0.4 (2009-11-27)

* support for 256 colors

## 1.0.3 (2009-7-26)

* rainbow methods don't mutate the original string object anymore

## 1.0.2 (2009-5-15)

* improved support for ruby 1.8.6 and 1.9.1

## 1.0.1 (2009-3-19)

* Windows support

## 1.0.0 (2008-7-21)

* initial version
