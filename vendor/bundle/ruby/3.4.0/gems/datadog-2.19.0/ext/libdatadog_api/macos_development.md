# Developing on macOS

As of this writing (August 2024), the libdatadog builds on rubygems.org only support Linux.

We don't officially support using libdatadog for Ruby on other platforms yet, but it is possible to use it for local development on macOS.
(**Note that you don't need these instructions if you develop inside docker.**)

Here's how you can do so:

1. [Install rust](https://www.rust-lang.org/tools/install)
2. Install `cbindgen`: `cargo install cbindgen`
3. Clone [libdatadog](https://github.com/datadog/libdatadog)
4. Create a folder for building into based on your ruby platform:

```
export DD_RUBY_PLATFORM=`ruby -e 'puts Gem::Platform.local.to_s'`
mkdir -p my-libdatadog-build/$DD_RUBY_PLATFORM
```

5. From inside of the libdatadog repo, build libdatadog into this folder: `./build-profiling-ffi.sh my-libdatadog-build/$DD_RUBY_PLATFORM`
6. Tell Ruby where to find libdatadog: `export LIBDATADOG_VENDOR_OVERRIDE=/full/path/to/my-libdatadog-build/` (Notice no platform here)
7. From dd-trace-rb, run `bundle exec rake clean compile`

If you additionally want to run the profiler test suite, also remember to `export DD_PROFILING_MACOS_TESTING=true` and re-run `rake clean compile`.

These instructions can quickly get outdated, so feel free to open an issue if they're not working (and/or ping @ivoanjo).
