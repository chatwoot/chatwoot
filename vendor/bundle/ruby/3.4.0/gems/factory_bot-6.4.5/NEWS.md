# News

## 6.4.5 (December 29, 2023)

  * Changed: Support Ruby 3.0+, Rails 6.1+ (Mike Burns).

## 6.4.4 (December 27, 2023)

  * Internal: Remove observer dependency (Earlopain).

## 6.4.3 (December 26, 2023)

  * Fix: Support models without ID setters in build_stubbed (Olivier Bellone).
  * Fix: Explicit observer dependency (Oleg Antonyan).
  * Internal: Add Rails 7.1 to CI (Olivier Bellone).
  * Internal: Bump github actions/checkout to v4 (Lorenzo Zabot)
  * Internal: Stop passing disable-error_highlight in CI (Mike Burns).
  * Internal: Relax the exception message check (Mike Burns).

## 6.4.2 (November 22, 2023)

  * Fix: top-level traits pass their class to ActiveSupport::Notifications
    (makicamel).

## 6.4.1 (November 20, 2023)

  * Fix: factories with traits pass their class to ActiveSupport::Notifications
    (makicamel).

## 6.4.0 (November 17, 2023)

  * Added: if `build_stubbed` detects a UUID primary key, generate the correct
    type (Peter Boling, Alexandre Ruban).
  * Docs: show examples of Ruby 3 syntactic sugars (Sean Doyle).
  * Internal: resolve test warning messages (Mike Burns).


## 6.3.0 (September 1, 2023)

  * Fix: link to changelog for RubyGems (Berkan Ünal).
  * Fix: integrate with Ruby 3.2's `did_you_mean` library (Daniel Colson).
  * Changed: explicitly define `#destroyed?` within the `Stub` strategy to return `false` to be consistent
    with ActiveRecord (Benjamin Fleischer).
  * Added: announce `factory_bot.compile_factory` notification (Sean Doyle).
  * Docs: clarify that custom strategies need to define `#to_sym` (Edmund Korley, Jonas S).
  * Docs: fix CI link in README (Mark Huk).
  * Docs: fix GitHub links (Robert Fletcher).
  * Docs: install this library with `bundle add` (Glauco Custódio).
  * Docs: re-write into mdBook (Mike Burns, Sara Jackson, Stefanni Brasil)
  * Docs: clarify that automatic trait definitions could introduce new linting errors (Lawrence Chou).
  * Internal: skip TruffleRuby on Rails 5.0, 5.1, 5.2 (Andrii Konchyn).
  * Internal: fix typoes throughout codebase (Yudai Takada).
  * Internal: run CI on `actions/checkout` v3 (Yudai Takada).
  * Internal: follow standardrb code style (Yudai Takada).
  * Internal: stop using Hound (Daniel Nolan).
  * Internal: only run simplecov on C Ruby (Daniel Colson).
  * Internal: quieter Cucumber (Daniel Colson).
  * Internal: Ruby 3.2 support (Daniel Colson).
  * Internal: Mike Burns is the CODEOWNER (Stefanni Brasil).

## 6.2.1 (March 8, 2022)
  * Added: CI testing against truffleruby
  * Changed: Documentation improvements for sequences and traits
  * Fixed: ActiveSupport::Notifications reporting strategy through associations now report as symbols
    * BREAKING CHANGE: Custom strategies now need to define a `to_sym` method to specify the strategy identifier
  * Fixed: `add_attribute` with reserved keywords assigns values correctly

## 6.2.0 (May 7, 2021)
  * Added: support for Ruby 3.0
  * Changed: Include factory or trait name in error messages for missing traits. d05a9a3c
  * Changed: Switched from Travis CI to GitHub Actions
  * Fixed: More Ruby 2.7 kwarg deprecation warnings

## 6.1.0 (July 8, 2020)
  * Added: public reader for the evaluation instance, helpful for building interrelated associations
  * Changed: raise a more helpful error when passing an invalid argument to an association
  * Fixed: Ruby 2.7 kwarg deprecation warnings

## 6.0.2 (June 19, 2020)
  * Fixed: bug causing traits to consume more memory each time they were used

## 6.0.1 (June 19, 2020)
  * Fixed: bug with constant resolution causing unexpected uninitialized constant errors

## 6.0.0 (June 18, 2020)
  * Added: automatic definition of traits for Active Record enum attributes, enabled by default
    (Note that this required changing where factory_bot constantizes the build
     class, which may affect applications that were using abstract factories for
     inheritance. See issue #1409.) (This may break `FactoryBot.lint` because
     there may be previously non-existing factory+trait combinations being
     defined and checked)
  * Added: `traits_for_enum` method to define traits for non-Active Record enums
  * Added: `build_stubbed_starting_id=` option to define the starting id for `build_stubbed`
  * Removed: deprecated methods on the top-level `FactoryBot` module meant only for internal use
  * Removed: support for EOL versions of Ruby (2.3, 2.4) and Rails (4.2)
  * Removed: support for "abstract" factories with no associated class; use traits instead.

## 5.2.0 (April 24, 2020)
  * Added: Pass index to block for `*_list` methods
  * Deprecated: methods on the top-level `FactoryBot` module meant only for internal use: `callbacks`, `configuration`, `constructor`, `initialize_with`, `register_sequence`, `resent_configuration`, `skip_create`, `to_create`

## 5.1.2 (March 25, 2020)
  * Fixed: Ruby 2.7 keyword deprecation warning in FactoryBot.lint

## 5.1.1 (October 2, 2019)
  * Improved: performance of traits
  * Fixed: registering strategies on JRuby

## 5.1.0 (September 21, 2019)
  * Added: "Did you mean?" style error message to help with typos in association declarations
  * Changed: `NoMethodError` for static attributes now offers a "Did you mean?" style message
  * Fixed: avoid undefining inherited evaluator methods
  * Fixed: avoid stubbing id for records without a primary key
  * Fixed: raise a helpful error for self-referencing traits to avoid a `SystemStackError`
  * Deprecated: methods on the top-level `FactoryBot` module meant only for internal use: `allow_class_lookup`, `allow_class_lookup`=, `register_trait`, `trait_by_name`, `traits`, `sequence_by_name`, `sequences`, `factory_by_name`, `register_factory`, `callback_names`, `register_callback`, `register_default_callbacks`, `register_default_strategies`, `strategies`

## 5.0.2 (February 22, 2019)
  * Bugfix: raise "Trait not registered" error when passing invalid trait arguments

## 5.0.1 (February 15, 2019)
  * Bugfix: Do not raise error when two sequences have the same name
    in two traits that have the same name

## 5.0.0 (February 1, 2019)
  * Added: Verbose option to include full backtraces in the linting output
  * Changed: use_parent_strategy now defaults to true, so by default the
    build strategy will build, rather than create associations
  * Changed: Passing a block when defining associations now raises an error
  * Bugfix: use_parent_strategy is no longer reset by FactoryBot.reload
  * Bugfix: rewind_sequences will now rewind local sequences along with the global ones
  * Bugfix: the build_stubbed strategy now sets timestamps without changing the
    the original behavior of the timestamp methods
  * Bugfix: avoid a stack error when referring to an "attributes" attribute in initialize_with
  * Removed: support for EOL versions of Ruby and Rails
  * Removed: static attributes (use dynamic attributes with a block instead)
  * Removed: looking up factories by class
  * Removed: ignore method (use transient instead)
  * Removed: duplicate_attribute_assignment_from_initialize_with configuration option
  * Deprecated: allow_class_lookup configuration option

## 4.11.1 (September 7, 2018)
  * Documentation: Include .yardopts in the gem to fix broken RubyDoc links

## 4.11.0 (August, 15, 2018)
  * Bugfix: Do not raise error for valid build_stubbed methods: decrement, increment, and toggle
  * Bugfix: Do not add timestamps with build_stubbed for objects that shouldn't have timestamps
  * Deprecate static attributes

## 4.10.0 (May 25, 2018)
  * Allow sequences to be rewound

## 4.9.0 (skipped - FactoryGirl only release)

## 4.8.2 (October 20, 2017)
  * Rename factory_girl to factory_bot

## 4.8.1 (September 28, 2017)
  * Explicitly define `#destroyed?` within the `Stub` strategy to return `nil` instead of raising
  * Update various dependencies
  * Update internal test suite to use RSpec's mocking/stubbing instead of mocha

## 4.8.0 (December 16, 2016)
  * Improve documentation
  * Add `FactoryGirl.generate_list` to be consistent with `build_list`/`create_list` and friends
  * Add `FactoryGirl.use_parent_strategy` configuration to allow associations to leverage parent build strategy

## 4.7.0 (April 1, 2016)
  * Improve documentation
  * Improve instrumentation payload to include traits, overrides, and the factory itself
  * Allow linting of traits
  * Deprecate factory lookup by class name in preparation for 5.0
  * Improve internal performance by using flat_map instead of map and compact
  * Improve handling of dirty attributes after building a stubbed object
  * Reduce warnings from redefining methods

## 4.6.0 (skipped)

## 4.5.0 (October 17, 2014)
  * Improve FactoryGirl.lint by including exception and message in output
  * Allow selective linting
  * Use more explicit #public_send when doing attribute assignment
  * Improve documentation around FactoryGirl.lint and initialize_with
  * Deprecate #ignore in favor of #transient

## 4.4.0 (February 10, 2014)
  * Add FactoryGirl.lint
  * Fix memory leak in duplicate traits
  * Update documentation

## 4.3.0 (November 3, 2013)
  * Start testing against Rails 4.0 and Ruby 2.0.0
  * Stop testing against Rails 3.0 and Ruby 1.9.2
  * Add `*_pair` methods to only build two objects
  * Raise if a method is defined with a FactoryGirl block (factory or trait)
  * Allow use of Symbol#to_proc in callbacks
  * Add global callbacks
  * Improve GETTING_STARTED and README

## 4.2.0 (January 18, 2013)
  * Improve documentation
  * Allow `*_list` syntax methods to accept a block
  * Update gem dependencies
  * Allow setting id for objects created with `build_stubbed`
  * Fix Stub strategy to mimic ActiveRecord regarding `created_at`
  * Evaluate sequences within the context of an Evaluator
  * Fix Mocha deprecation warning
  * Fix some warnings when running RUBYOPT=-w rake
  * Convert test suite to RSpec's "expect" syntax

## 4.1.0 (September 11, 2012)
  * Allow multiple callbacks to bind to the same block
  * Fix documentation surrounding the stub strategy

## 4.0.0 (August 3, 2012)
  * Remove deprecated cucumber_steps
  * Remove deprecated alternate syntaxes
  * Deprecate duplicate_attribute_assignment_from_initialize_with, which is now unused
    as attributes assigned within initialize_with are not subsequently assigned

## 3.6.1 (August 2, 2012)
  Update README to include info about running with JRuby
  * Update dependencies on RSpec and tiny versions of Rails in Appraisal
  * Improve flexibility of using traits with associations and add documentation
  * Stub update_column to raise to mirror ActiveRecord's change from update_attribute

## 3.6.0 (July 27, 2012)
  * Code/spec cleanup
  * Allow factories with traits to be used in associations
  * Refactor Factory to use DefinitionHierarchy to handle managing callbacks,
    custom constructor, and custom to_create
  * Add memoization to speed up factories providing attribute overrides
  * Add initial support of JRuby when running in 1.9 mode
  * Improve docs on what happens when including FactoryGirl::Syntax::Methods

## 3.5.0 (June 22, 2012)
  * Allow created_at to be set when using build_stubbed
  * Deprecate FactoryGirl step definitions

## 3.4.2 (June 19, 2012)
  * Fix bug in traits with callbacks called implicitly in factories whose
    callbacks trigger multiple times

## 3.4.1 (June 18, 2012)
  * Fix traits so they can be nested and referred to from other traits

## 3.4.0 (June 11, 2012)
  * Sequences support Enumerators
  * Optionally disable duplicate assignment of attributes in initialize_with
  * Make hash of public attributes available in initialize_with
  * Support referring to a factory based on class name

## 3.3.0 (May 13, 2012)
  * Allow to_create, skip_create, and initialize_with to be defined globally
  * Allow to_create, skip_create, and initialize_with to be defined within traits
  * Fix deprecation messages for alternate syntaxes (make, generate, etc.)
  * Improve library documentation
  * Deprecate after_build, after_create, before_create, after_stub in favor of new callbacks
  * Introduce new callback syntax: after(:build) {}, after(:custom) {}, or callback(:different) {}
    This allows for declaring any callback, usable with custom strategies
  * Add attributes_for_list and build_stubbed_list with the StrategySyntaxMethodRegistrar
  * Allow use of syntax methods (build, create, generate, etc) implicitly in callbacks
  * Internal refactoring of a handful of components

## 3.2.0 (April 24, 2012)
  * Use AS::Notifications for pub/sub to track running factories
  * Call new within initialize_with implicitly on the build class
  * Skip to_create with skip_create
  * Allow registration of custom strategies
  * Deprecate alternate syntaxes
  * Implicitly call factory_bot's syntax methods from dynamic attributes

## 3.1.0 (April 6, 2012)
  * Sequences support aliases, which reference the same block
  * Update documentation
  * Add before_create callback
  * Support use of #attribute_names method to determine available attributes for steps
  * Use ActiveSupport::Deprecation for all deprecations

## 3.0.0 (March 23, 2012)
  * Deprecate the vintage syntax
  * Remove Rails 2.x support
  * Remove Ruby 1.8 support
  * Remove deprecated features, including default_strategy, factory_name,
    :method for defining default strategy, ignore on individual attributes, and
    interacting with Factory the way you would FactoryGirl

## 2.6.4 (March 16, 2012)
  * Do not ignore names of transient attributes
  * Ensure attributes set on instance are calculated uniquely

## 2.6.3 (March 9, 2012)
  * Fix issue with traits not being present the first time a factory is accessed
  * Update available Cucumber step definitions to not require a trailing colon
    when building a table of attributes to instantiate records with

## 2.6.2 (March 9, 2012)
  * Allow factories to use all their ancestors' traits
  * Ignore bin dir generated by bundler
  * Namespace ::Factory as top-level to fix vintage syntax issue with
    Ruby 1.9.2-p3p18

## 2.6.1 (March 2, 2012)
  * Use FactoryGirl.reload in specs
  * Clean up running named factories with a particular strategy with
    FactoryGirl::FactoryRunner

## 2.6.0 (February 17, 2012)
  * Improve documentation of has_many associations in the GETTING_STARTED
    document
  * Deprecate :method in favor of :strategy when overriding an association's
    build strategy

## 2.5.2 (February 10, 2012)
  * Fix step definitions to use associations defined in parent factories
  * Add inline trait support to (build|create)_list
  * Update ActiveSupport dependency to >= 2.3.9, which introduced
    class_attribute

## 2.5.1 (February 3, 2012)
  * Fix attribute evaluation when the attribute isn't defined in the factory but
    is a private method on Object
  * Update rubygems on Travis before running tests
  * Fix spec name
  * Update GETTING_STARTED with correct usage of build_stubbed
  * Update README with more info on initialize_with
  * Honor :parent on factory over block nesting

## 2.5.0 (January 20, 2012)
  * Revert 'Deprecate build_stubbed and attributes_for'
  * Implement initialize_with to allow overriding object instantiation
  * Ensure FG runs against Rails 3.2.0

## 2.4.2 (January 18, 2012)
  * Fix inline traits' interaction with defaults on the factory

## 2.4.1 (January 17, 2012)
  * Deprecate build_stubbed and attributes_for
  * Fix inline traits

## 2.4.0 (January 13, 2012)
  * Refactor internals of FactoryGirl to use anonymous class on which attributes
    get defined
  * Explicitly require Ruby 1.8.7 or higher in gemspec
  * Fix documentation
  * Add Gemnasium status to documentation
  * Supplying a Class to a factory that overrides to_s no longer results in
    getting the wrong Class constructed
  * Be more agnostic about ORMs when using columns in FactoryGirl step
    definitions
  * Test against Active Record 3.2.0.rc2
  * Update GETTING_STARTED to use Ruby syntax highlighting

## 2.3.2 (November 26, 2011)
  * Move logic of where instance.save! is set to Definition
  * Fix method name from aliases_for? to alias_for?
  * Refactor internal attribute handling to use an anonymous class instead of
    faking Ruby's variable resolution. This allows for more sane usage of
    attributes without having to manage sorting priority because attributes
    can turn themselves into procs, which are used with define_method on a
    class so attributes work correctly all the time.

## 2.3.1 (November 23, 2011)
  * Remove internally-used associate method from all the FactoryGirl::Proxy subclasses
  * Move around requiring of files
  * Consolidate errors into factory_bot.rb
  * Refactor AttributeList to deal with priority only when iterating over
    attributes
  * Refactor internals of some of the Proxy subclasses
  * Ensure callbacks on traits are executed in the correct order

## 2.3.0 (November 18, 2011)
  * Registries are named, resulting in better messages when factories, traits,
    or sequences cannot be found
  * Fix incorrect tests
  * Internals refactoring introducing FactoryGirl::NullFactory,
    FactoryGirl::Definition, and FactoryGirl::DeclarationList
  * Use ActiveSupport for Hash#except and its delegation capabilities
  * Fix usage of callbacks when added via implicit traits
  * Use Bundler tasks and clean up dependencies
  * Fix failing spec for big letters in factory name passed as symbol
  * Add ability for traits to be added dynamically when creating an instance via
    build, create, build_stubbed, or attributes_for

## 2.2.0 (October 14, 2011)
  * Clean up RSpec suite to not use 'should'
  * Use create_list in step definitions
  * Syntax methods that deal with ORM interaction (attributes_for, build, build_stubbed,
    and create) now accept a block that yields the result. This results in a
    more convenient way to interact with the result than using Object.tap.
  * Standardize deprecation warnings
  * Update transient attribute syntax to use blocks instead of calling ignore on
    each attribute declaration
  * Parents can be defined after children because factories are evaluated when
    they're used; this means breaking up factories across multiple files will
    behave as expected
  * Large internal refactoring, including changing access modifiers for a
    handful of methods for a more clearly defined API

## 2.1.2 (September 23, 2011)
  * Bugfix: Vintage syntax fixed after bug introduced in 2.1.1
  * Introduce dependency on activesupport to remove code from Factory class

## 2.1.1 (September 23, 2011) (yanked)
  * Bugfix: Parent object callbacks are run before child object callbacks
  * Declarations: allow overriding/modification of individual traits in child factories
  * Callbacks refactored to not be attributes
  * Updating documentation for formatting and clarity (incl. new specificity for cucumber)

## 2.1.0 (September 02, 2011)
  * Bugfix: created_at now defined for stubbed models
  * Gemspec updated for use with Rails 3.1
  * Factories can now be modified post-definition (useful for overriding defaults from gems/plugins)
  * All factories can now be reloaded with Factory.reload
  * Add :method => build to factory associations to prevent saving of associated objects
  * Factories defined in {Rails.root}/factories are now loaded by default
  * Various documentation updates

## 1.1.4 (November 28, 2008)
  * Factory.build now uses Factory.create for associations of the built object
  * Factory definitions are now detected in subdirectories, such as
    factories/person_factory.rb (thanks to Josh Nichols)
  * Factory definitions are now loaded after the environment in a Rails project
    (fixes some issues with dependencies being loaded too early) (thanks to
    Josh Nichols)
  * Factory names ending in 's' no longer cause problems (thanks to Alex Sharp
    and Josh Owens)

## 1.1.3 (September 12, 2008)
  * Automatically pull in definitions from factories.rb, test/factories.rb, or
    spec/factories.rb
## 1.1.2 (July 30, 2008)
  * Improved error handling for invalid and undefined factories/attributes
  * Improved handling of strings vs symbols vs classes
  * Added a prettier syntax for handling associations
  * Updated documentation and fixed compatibility with Rails 2.1

## 1.1.1 (June 23, 2008)
  * The attribute "name" no longer requires using #add_attribute

## 1.1.0 (June 03, 2008)
  * Added support for dependent attributes
  * Fixed the attributes_for build strategy to not build associations
  * Added support for sequences

## 1.0.0 (May 31, 2008)
  * First version
