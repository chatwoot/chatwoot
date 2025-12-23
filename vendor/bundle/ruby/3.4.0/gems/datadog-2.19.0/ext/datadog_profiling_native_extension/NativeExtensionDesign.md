# Profiling Native Extension Design

The profiling native extension is used to:

1. Implement features which are expensive (in terms of resources) or otherwise impossible to implement using Ruby code.
2. Bridge between Ruby-specific profiling features and [`libdatadog`](https://github.com/DataDog/libdatadog), a Rust-based
library with common profiling functionality.

Due to (1), this extension is quite coupled with MRI Ruby ("C Ruby") internals, and is not intended to support other rubies such as
JRuby or TruffleRuby. When below we say "Ruby", read it as "MRI Ruby".

## Disabling

The profiling native extension can be disabled by setting `DD_PROFILING_NO_EXTENSION=true` when installing
the gem. Setting `DD_PROFILING_NO_EXTENSION` at installation time skips compilation of the extension entirely.

(If you're a customer and needed to use this, please tell us why on <https://github.com/DataDog/dd-trace-rb/issues/new>.)

Disabling the profiler extension will disable profiling.

## Who is this page for?

**This documentation is intended to be used by dd-trace-rb developers. Please see the `docs/` folder for user-level
documentation.**

## Must not block or break users that cannot use it

The profiling native extension is (and must always be) designed to **not cause failures** during gem installation, even
if some features, Ruby versions, or operating systems are not supported.

E.g. the extension must not break installation on Ruby 2.5 (or the oldest Ruby version we support at the time) on 64-bit ARM macOS,
even if at run time it will effectively do nothing for such a setup.

We have a CI setup to help validate this, but this is really important to keep in mind when adding to or changing the
existing codebase.

## Memory leaks and Interaction with Ruby VM APIs

When adding to or changing the native extension, we must always consider what API calls can lead to Ruby exceptions to
be raised, and whether there are is dynamically-allocated memory that can be leaked if that happens.

(When a Ruby exception is raised, the VM will use `setjmp` and `longjmp` to jump back in the stack and thus skip
our clean-up code, like in a Ruby-level exception.)

We avoid issues using a combination of:

* Avoiding dynamic allocation as much as possible
* Getting all needed data and doing all validations before doing any dynamic allocations
* Avoiding calling Ruby VM APIs after doing dynamic allocations
* Wrapping dynamic allocations into Ruby GC-managed objects (using `TypedData_Wrap_Struct`), so that Ruby will manage
  their lifetime and call `free` when the GC-managed object is no longer being referenced
* Using [`rb_protect` and similar APIs](https://silverhammermba.github.io/emberb/c/?#rescue) to run cleanup code on
  exception cases

Non-exhaustive list of APIs that cause exceptions to be raised:

* `Check_TypedStruct`, `Check_Type`, `ENFORCE_TYPE`
* `rb_funcall`
* `rb_thread_call_without_gvl`
* [Numeric conversion APIs, e.g. `NUM2LONG`, `NUM2INT`, etc.](https://silverhammermba.github.io/emberb/c/?#translation)
* Our `char_slice_from_ruby_string` helper

## Usage of private VM headers

To implement some of the features below, we sometimes require access to private Ruby header files (that describe VM
internal types, structures and functions).

Because these private header files are not included in regular Ruby installations, we have two different workarounds:

1. for Ruby versions 2.6 to 3.2 we make use use the Ruby private MJIT header
2. for Ruby versions < 2.6 and > 3.2 we make use of the `datadog-ruby_core_source` gem

Functions which make use of these headers are defined in the <private_vm_api_acccess.c> file.

There is currently no way for disabling usage of the private MJIT header for Ruby 2.6 to 3.2.

**Important Note**: Our medium/long-term plan is to stop relying on all private Ruby headers, and instead request and
contribute upstream changes so that they become official public VM APIs.

### Approach 1: Using the Ruby private MJIT header

Ruby versions 2.6 to 3.2 shipped a JIT compiler called MJIT. This compiler does not directly generate machine code;
instead it generates C code and uses the system C compiler to turn it into machine code.

The generated C code `#include`s a private header -- which we call "the MJIT header".
The MJIT header gets shipped with all MJIT-enabled Rubies and includes the layout of many internal VM structures;
and of course the intention is that it is only used by the Ruby MJIT compiler.

This header is placed inside the `include/` directory in a Ruby installation, and is named for that specific Ruby
version. e.g. `rb_mjit_min_header-2.7.4.h`.

This header was removed in Ruby 3.3.

### Approach 2: Using the `datadog-ruby_core_source` gem

The [`datadog-ruby_core_source`](https://github.com/DataDog/datadog-ruby_core_source) contains almost no code;
instead, it just contains per-Ruby-version folders with the private VM headers (`.h`) files for that version.

Thus, even though a regular Ruby installation does not include these files, we can access the copy inside this gem.

## Feature: Getting thread CPU-time clock_ids

* **OS support**: Linux

To enable CPU-time profiling, we use the `pthread_getcpuclockid(pthread_t thread, clockid_t *clockid)` C function to
obtain a `clockid_t` that can then be used with the `clock_gettime` function.

The challenge with using `pthread_getcpuclockid()` is that we need to get the `pthread_t` for a given Ruby `Thread`
object. We previously did this with a weird combination of monkey patching and `pthread_self()` (effectively patching
every `Thread` to run `pthread_self()` at initialization time and stash that value somewhere), but this had a number
of downsides.

The approach we use in the profiling native extension is to reach inside the internal structure of the `Thread` object,
and extract the `pthread_t` that Ruby itself keeps, but does not expose. This is implemented in the `pthread_id_for()`
function in `private_vm_api_acccess.c`. Thus, using this trick we can at any point in execution go from a `Thread`
object into the `clockid_t` that we need.

Note that `pthread_getcpuclockid()` is not available on macOS (nor, obviously, on Windows), and hence this feature
is currently Linux-specific. Thus, in the <clock_id_from_pthread.c> file we implement the feature for supported Ruby
setups but if something is missing we instead compile in <clock_id_noop.c> that includes a no-op implementation of the
feature.

## Fork-safety

It's common for Ruby applications to create child processes via the use of `fork`. For instance, this strategy is used
by the puma webserver and the resque job processing tool.

Thus, the profiler needs to be designed to take this into account. I'll call out two important parts of this design:

1. Automatically propagate profiler to child processes. To make onboarding easier, we monkey patch the Ruby `fork` APIs
so that the profiler is automatically restarted in child processes. This way, the user only needs to start profiling at
the beginning of their application, and automatically forks are profiled as well.

2. The profiler must ensure correctness and stability even if the application forks. There must be no impact on the
application or incorrect data generated.

### Fork-safety for libdatadog

Since libdatadog is built in native code (Rust), special care needs to be take to consider how we're using it and how
it can be affected by the use of `fork`.

* Profile-related APIs: `Profile_new` and `Profile_add` and `Profile_free` are only called with the Ruby Global VM Lock
being held. Thus, if Ruby APIs are being used for fork, this prevents any concurrency between profile mutation and
forking, because if we’re holding the lock, then no other thread can call into the fork APIs.
(Calling libc `fork()` directly from a native extension is possible but would break the VM as well, since it does need
to do some of its own work when forking happens, so we’ll ignore that one)

* Exporter-related APIs: Explicitly to make sure we had no issues with forking, we create a new `CancellationToken_new`
and `ProfileExporterV3_new` for every report. We do release the Global VM Lock during exporting, so it's possible for
forking and exporting to be concurrent.

  Both the CancellationToken and ProfileExporter are only referenced on the stack of the thread doing the exporting, so
  they will not be reused in the child process after the fork. In the worst case, if a report is concurrent with a fork,
  then it's possible a small amount of memory will not be cleaned up in the child process.

  Because there is no leftover undefined state, we guarantee correctness for the exporter APIs.
