# `datadog-ruby_core_source`

## Description

This gem is a fork of [debase-ruby\_core\_source](https://github.com/ruby-debug/debase-ruby_core_source/) for [dd-trace-rb](https://github.com/DataDog/dd-trace-rb).

Only Ruby 2.5 and 3.3+ Rubies are included [see here for more information on why](https://github.com/DataDog/dd-trace-rb/blob/master/ext/datadog_profiling_native_extension/NativeExtensionDesign.md#usage-of-private-vm-headers).

## Usage

Example use in extconf.rb:

```ruby
require 'datadog/ruby_core_source'
hdrs = proc { have_header("vm_core.h") and have_header("iseq.h") }
dir_config("ruby") # allow user to pass in non-standard core include directory
if !Datadog::RubyCoreSource::create_makefile_with_core(hdrs, "foo")
  # error
  exit(1)
end
```

To add another ruby version's source to this gem's directory:

    $ rake add_source VERSION=2.1.3 PATCHLEVEL=242

_Adding released versions_. `add_source` can use a pre-downloaded .tgz file. Use TGZ_FILE_NAME to pass it. Note that the PATCHLEVEL variable is optional because `add_source` can extract the patch level from version.h of the downloaded sources.

Then, run the `find_includes.rb` to minimize the shipped files. See comments on that file for how to use it, and/or reference previous PRs.

## Credits

The following credits are in the upstream `debase-ruby_core_source` README:

* @valich for 2.5.0-preview1 headers and src-based ruby support
* @dirknilius for 2.2.3 headers
* @andremedeiros for 2.1.1 headers
* @formigarafa for fixing 2.1.0 headers

## LICENSE
Ruby library code is MIT license - see LICENSE.txt.  Included ruby headers,
lib/datadog/ruby\_core\_source/, are mostly Ruby license - see RUBY\_LICENSE. Some headers have their own licenses - see LEGAL.
