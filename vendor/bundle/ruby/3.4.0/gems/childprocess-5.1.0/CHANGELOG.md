### Version 5.1.0 / 2024-01-06

* [#196](https://github.com/enkessler/childprocess/pull/196): Remove `ostruct` dependency to fix deprecation warning on Ruby 3.4
* [#199](https://github.com/enkessler/childprocess/pull/199): Add `logger` dependency to fix deprecation warning on Ruby 3.4

### Version 5.0.0 / 2024-01-06

* [#175](https://github.com/enkessler/childprocess/pull/175): Replace all backends by `Process.spawn` for portability, reliability and simplicity.
* [#185](https://github.com/enkessler/childprocess/pull/185): Add support for Ruby 3.x

### Version 4.1.0 / 2021-06-08

* [#170](https://github.com/enkessler/childprocess/pull/170): Update gem homepage to use `https://`
* [#177](https://github.com/enkessler/childprocess/pull/177): Add ARM64-macos support

### Version 4.0.0 / 2020-06-18

* [#167](https://github.com/enkessler/childprocess/pull/167): Fix detach behavior on Windows
* [#168](https://github.com/enkessler/childprocess/pull/168): Drop support for Ruby 2.3

### Version 3.0.0 / 2019-09-20

* [#156](https://github.com/enkessler/childprocess/pull/156): Remove unused `rubyforge_project` from gemspec
* [#160](https://github.com/enkessler/childprocess/pull/160): Remove extension to conditionally install `ffi` gem on Windows platforms
* [#160](https://github.com/enkessler/childprocess/pull/160): Remove runtime dependency on `rake` gem

### Version 2.0.0 / 2019-07-11

* [#148](https://github.com/enkessler/childprocess/pull/148): Drop support for Ruby 2.0, 2.1, and 2.2
* [#149](https://github.com/enkessler/childprocess/pull/149): Fix Unix fork reopen to be compatible with Ruby 2.6
* [#152](https://github.com/enkessler/childprocess/pull/152)/[#154](https://github.com/enkessler/childprocess/pull/154): Fix hangs and permission errors introduced in Ruby 2.6 for leader processes of process groups

### Version 1.0.1 / 2019-02-03

* [#143](https://github.com/enkessler/childprocess/pull/144): Fix installs by adding `rake` gem as runtime dependency
* [#147](https://github.com/enkessler/childprocess/pull/147): Relax `rake` gem constraint from `< 12` to `< 13`

### Version 1.0.0 / 2019-01-28

* [#134](https://github.com/enkessler/childprocess/pull/134): Add support for non-ASCII characters on Windows
* [#132](https://github.com/enkessler/childprocess/pull/132): Install `ffi` gem requirement on Windows only
* [#128](https://github.com/enkessler/childprocess/issues/128): Convert environment variable values to strings when `posix_spawn` enabled
* [#141](https://github.com/enkessler/childprocess/pull/141): Support JRuby on Java >= 9

### Version 0.9.0 / 2018-03-10

* Added support for DragonFly BSD.


### Version 0.8.0 / 2017-09-23

* Added a method for determining whether or not a process had been started.


### Version 0.7.1 / 2017-06-26

* Fixed a noisy uninitialized variable warning


### Version 0.7.0 / 2017-05-07

* Debugging information now uses a Logger, which can be configured.


### Version 0.6.3 / 2017-03-24

See beta release notes.


### Version 0.6.3.beta.1 / 2017-03-10

* Bug fix: Fixed child process creation problems on Windows 7 when a child was declared as a leader.


### Version 0.6.2 / 2017-02-25

* Bug fix: Fixed a potentially broken edge case that could occur on older 32-bit OSX systems.


### Version 0.6.1 / 2017-01-22

* Bug fix: Fixed a dependency that was accidentally declared as a runtime
  dependency instead of a development dependency.


### Version 0.6.0 / 2017-01-22

* Support for Ruby 2.4 added


### Version 0.5.9 / 2016-01-06

* The Great Before Times...
