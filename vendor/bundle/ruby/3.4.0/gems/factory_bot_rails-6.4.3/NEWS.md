factory\_bot\_rails versioning is synced with factory\_bot releases. For this reason
there might not be any notable changes in new versions of this project.

# NEWS

## 6.4.3 (December 29, 2023)

* Changed: allow sequence definitions for ActiveRecord primary keys (Mike
  Burns).
* Changed: Support Ruby 3.0+, Rails 6.1+ (Mike Burns)
* Documentation improvements (obregonia1).
* Internal: GitHub Actions improvements (Lorenzo Zabot, ydah).
* Internal: RubyGems points to changelog (Tilo Sloboda).
* Internal: Bump standard, rake, activerecord, appraisal, rspec-rails (Mike
  Burns).

## 6.4.2 (November 23, 2023)
* Fixed: Fix Rails 7.1.2 + monkey-patched ActiveRecord compatibility (Adif
  Sgaid, Benoit Tigeot)
* Internal: Test against Rails 7.1 (y-yagi)
* Internal: Fix links to old files after renaming the main branch to `main`
  (y-yagi)

## 6.4.0 (November 17, 2023)

* Releasing this for consistency with the factory\_bot dependency.

## 6.3.0 (November 17, 2023)

* Changed: reject sequence definitions for ActiveRecord primary keys (Sean
  Doyle).
* Changed: factory\_bot dependency to ~> 6.4 (Mike Burns).
* Changed: upgrade dependencies (Daniel Colson).
* Add: `projections.json` for Rails.vim (Caleb Hearth).
* Docs: fix broken link (Edu Depetris).
* Docs: mention Rails generator in docs (Edu Depetris).
* Docs: fix typo (Yudai Takada).
* Internal: skip Spring version 2.1.1 due to a bug in that release (Christina
  Entcheva, Daniel Colson).
* Internal: test against Rails 6.1 (Antonis Berkakis).
* Internal: test against Ruby 3 (Daniel Colson).
* Internal: fewer warnings in Cucumber tests (Daniel Colson).
* Internal: use GitHub Actions for CI (Mathieu Jobin).
* Internal: a whole bunch of cleanup (Daniel Colson).
* Internal: fix CI due to a Bundler output change (Mike Burns).

## 6.2.0 (May 7, 2021)

* Changed: factory\_bot dependency to ~> 6.2.0

## 6.1.0 (July 8, 2020)

* Changed: factory\_bot dependency to ~> 6.1.0

## 6.0.0 (June 18, 2020)

* Fixed: generate a plural factory name when the --force-plural flag is provided
* Changed: factory\_bot dependency to ~> 6.0.0
* Removed: `"factory_bot.register_reloader"` initializer, now registering the
  reloader after application initialization
* Removed: support for EOL versions of Ruby (2.3, 2.4) and Rails (4.2)

## 5.2.0 (April 26, 2020)

* Changed: factory\_bot dependency to ~> 5.2.0

## 5.1.1 (September 24, 2019)

* Fixed: Ensure definitions do not load before I18n is initialized

## 5.1.0 (September 24, 2019)

* Changed: factory\_bot dependency to ~> 5.1.0

## 5.0.2 (April 14, 2019)

* Bugfix: Reload factory\_bot whenever the application changes to avoid holding
  onto stale object references
* Bugfix: Avoid watching project root when no factory definitions exist

## 5.0.1 (February 9, 2019)

* Bugfix: Avoid watching files and directories that don't exist (to avoid a
  file watching bug in Rails https://github.com/rails/rails/issues/32700)

## 5.0.0 (February 1, 2019)

* Added: calling reload! in the Rails console will reload any factory definition files that have changed
* Added: support for custom generator templates
* Added: `definition_file_paths` configuration option, making it easier to place factories in custom locations
* Changed: namespaced models are now generated inside a directory matching the namespace
* Changed: added newline between factories generated into the same file
* Removed: support for EOL version of Ruby and Rails

## 4.11.1 (September 7, 2018)

* Update generator to use dynamic attributes instead of deprecated static attributes

## 4.11.0 (August 16, 2018)

* No notable changes

## 4.10.0 (May 25, 2018)

* No notable changes

## 4.8.2 (October 20, 2017)

* Rename factory\_girl\_rails to factory\_bot\_rails

## 4.7.0 (April 1, 2016)

* No notable changes

## 4.6.0 (February 1, 2016)

* No notable changes

## 4.5.0 (October 17, 2014)

* Improved README

## 4.4.1 (February 26, 2014)

* Support Spring

## 4.2.1 (February 8, 2013)

* Fix bug when configuring FG and RSpec fixture directory
* Remove debugging
* Require factory\_girl\_rails explicitly in generator

## 4.2.0 (January 25, 2013)

* Add appraisal and get test suite working reliably with turn gem
* Support MiniTest
* Allow a custom directory for factories to be specified
