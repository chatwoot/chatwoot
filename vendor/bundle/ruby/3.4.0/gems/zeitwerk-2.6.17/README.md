# Zeitwerk



[![Gem Version](https://img.shields.io/gem/v/zeitwerk.svg?style=for-the-badge)](https://rubygems.org/gems/zeitwerk)
[![Build Status](https://img.shields.io/github/actions/workflow/status/fxn/zeitwerk/ci.yml?branch=main&event=push&style=for-the-badge)](https://github.com/fxn/zeitwerk/actions/workflows/ci.yml?query=branch%3Amain)


<!-- TOC -->

- [Introduction](#introduction)
- [Synopsis](#synopsis)
- [File structure](#file-structure)
  - [The idea: File paths match constant paths](#the-idea-file-paths-match-constant-paths)
  - [Inner simple constants](#inner-simple-constants)
  - [Root directories and root namespaces](#root-directories-and-root-namespaces)
    - [The default root namespace is `Object`](#the-default-root-namespace-is-object)
    - [Custom root namespaces](#custom-root-namespaces)
    - [Nested root directories](#nested-root-directories)
  - [Implicit namespaces](#implicit-namespaces)
  - [Explicit namespaces](#explicit-namespaces)
  - [Collapsing directories](#collapsing-directories)
  - [Testing compliance](#testing-compliance)
- [Usage](#usage)
  - [Setup](#setup)
    - [Generic](#generic)
    - [for_gem](#for_gem)
    - [for_gem_extension](#for_gem_extension)
  - [Autoloading](#autoloading)
  - [Eager loading](#eager-loading)
    - [Eager load exclusions](#eager-load-exclusions)
    - [Eager load directories](#eager-load-directories)
    - [Eager load namespaces](#eager-load-namespaces)
    - [Eager load namespaces shared by several loaders](#eager-load-namespaces-shared-by-several-loaders)
    - [Global eager load](#global-eager-load)
  - [Loading individual files](#loading-individual-files)
  - [Reloading](#reloading)
    - [Configuration and usage](#configuration-and-usage)
    - [Thread-safety](#thread-safety)
  - [Inflection](#inflection)
    - [Zeitwerk::Inflector](#zeitwerkinflector)
    - [Zeitwerk::GemInflector](#zeitwerkgeminflector)
    - [Zeitwerk::NullInflector](#zeitwerknullinflector)
    - [Custom inflector](#custom-inflector)
  - [Callbacks](#callbacks)
    - [The on_setup callback](#the-on_setup-callback)
    - [The on_load callback](#the-on_load-callback)
    - [The on_unload callback](#the-on_unload-callback)
    - [Technical details](#technical-details)
  - [Logging](#logging)
    - [Loader tag](#loader-tag)
  - [Ignoring parts of the project](#ignoring-parts-of-the-project)
    - [Use case: Files that do not follow the conventions](#use-case-files-that-do-not-follow-the-conventions)
    - [Use case: The adapter pattern](#use-case-the-adapter-pattern)
    - [Use case: Test files mixed with implementation files](#use-case-test-files-mixed-with-implementation-files)
  - [Shadowed files](#shadowed-files)
  - [Edge cases](#edge-cases)
  - [Beware of circular dependencies](#beware-of-circular-dependencies)
  - [Reopening third-party namespaces](#reopening-third-party-namespaces)
  - [Introspection](#introspection)
    - [`Zeitwerk::Loader#dirs`](#zeitwerkloaderdirs)
    - [`Zeitwerk::Loader#cpath_expected_at`](#zeitwerkloadercpath_expected_at)
    - [`Zeitwerk::Loader#all_expected_cpaths`](#zeitwerkloaderall_expected_cpaths)
  - [Encodings](#encodings)
  - [Rules of thumb](#rules-of-thumb)
  - [Debuggers](#debuggers)
- [Pronunciation](#pronunciation)
- [Supported Ruby versions](#supported-ruby-versions)
- [Testing](#testing)
- [Motivation](#motivation)
  - [Kernel#require is brittle](#kernelrequire-is-brittle)
  - [Rails autoloading was brittle](#rails-autoloading-was-brittle)
- [Awards](#awards)
- [Thanks](#thanks)
- [License](#license)

<!-- /TOC -->

<a id="markdown-introduction" name="introduction"></a>
## Introduction

Zeitwerk is an efficient and thread-safe code loader for Ruby.

Given a [conventional file structure](#file-structure), Zeitwerk is capable of loading your project's classes and modules on demand (autoloading) or upfront (eager loading). You don't need to write `require` calls for your own files; instead, you can streamline your programming by knowing that your classes and modules are available everywhere. This feature is efficient, thread-safe, and aligns with Ruby's semantics for constants.

Zeitwerk also supports code reloading, which can be useful during web application development. However, coordination is required to reload in a thread-safe manner. The documentation below explains how to achieve this.

The gem is designed to allow any project, gem dependency, or application to have its own independent loader. Multiple loaders can coexist in the same process, each managing its own project tree and operating independently of each other. Each loader has its own configuration, inflector, and optional logger.

Internally, Zeitwerk exclusively uses absolute file names when issuing `require` calls, eliminating the need for costly file system lookups in `$LOAD_PATH`. Technically, the directories managed by Zeitwerk don't even need to be in `$LOAD_PATH`.

Furthermore, Zeitwerk performs a single scan of the project tree at most, lazily descending into subdirectories only when their namespaces are used.

<a id="markdown-synopsis" name="synopsis"></a>
## Synopsis

Main interface for gems:

```ruby
# lib/my_gem.rb (main file)

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module MyGem
  # ...
end

loader.eager_load # optionally
```

Main generic interface:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.setup # ready!
```

The `loader` variable can go out of scope. Zeitwerk keeps a registry with all of them, and so the object won't be garbage collected.

You can reload if you want to:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.enable_reloading # you need to opt-in before setup
loader.setup
...
loader.reload
```

and you can eager load all the code:

```ruby
loader.eager_load
```

It is also possible to broadcast `eager_load` to all instances:

```ruby
Zeitwerk::Loader.eager_load_all
```

<a id="markdown-file-structure" name="file-structure"></a>
## File structure

<a id="markdown-the-idea-file-paths-match-constant-paths" name="the-idea-file-paths-match-constant-paths"></a>
### The idea: File paths match constant paths

For Zeitwerk to work with your file structure, simply name files and directories after the classes and modules they define:

```
lib/my_gem.rb         -> MyGem
lib/my_gem/foo.rb     -> MyGem::Foo
lib/my_gem/bar_baz.rb -> MyGem::BarBaz
lib/my_gem/woo/zoo.rb -> MyGem::Woo::Zoo
```

You can fine-tune this behavior by [collapsing directories](#collapsing-directories) or [ignoring specific parts of the project](#ignoring-parts-of-the-project), but that is the main idea.

<a id="markdown-inner-simple-constants" name="inner-simple-constants"></a>
### Inner simple constants

While a simple constant like `HttpCrawler::MAX_RETRIES` can be defined in its own file:

```ruby
# http_crawler/max_retries.rb
HttpCrawler::MAX_RETRIES = 10
```

that is not required, you can also define it the regular way:

```ruby
# http_crawler.rb
class HttpCrawler
  MAX_RETRIES = 10
end
```

The first example needs a custom [inflection](#inflection) rule:

```ruby
loader.inflector.inflect("max_retries" => "MAX_RETRIES")
```

Otherwise, Zeitwerk would expect the file to define `MaxRetries`.

In the second example, no custom rule is needed.

<a id="markdown-root-directories-and-root-namespaces" name="root-directories-and-root-namespaces"></a>
### Root directories and root namespaces

Every directory configured with `push_dir` is called a _root directory_, and they represent _root namespaces_.

<a id="markdown-the-default-root-namespace-is-object" name="the-default-root-namespace-is-object"></a>
#### The default root namespace is `Object`

By default, the namespace associated to a root directory is the top-level one: `Object`.

For example, given

```ruby
loader.push_dir("#{__dir__}/models")
loader.push_dir("#{__dir__}/serializers"))
```

these are the expected classes and modules being defined by these files:

```
models/user.rb                 -> User
serializers/user_serializer.rb -> UserSerializer
```

<a id="markdown-custom-root-namespaces" name="custom-root-namespaces"></a>
#### Custom root namespaces

Although `Object` is the most common root namespace, you have the flexibility to associate a different one with a specific root directory. The `push_dir` method accepts a non-anonymous class or module object as the optional `namespace` keyword argument.

For example, given:

```ruby
require "active_job"
require "active_job/queue_adapters"
loader.push_dir("#{__dir__}/adapters", namespace: ActiveJob::QueueAdapters)
```

a file defining `ActiveJob::QueueAdapters::MyQueueAdapter` does not need the conventional parent directories, you can (and have to) store the file directly below `adapters`:

```
adapters/my_queue_adapter.rb -> ActiveJob::QueueAdapters::MyQueueAdapter
```

Please note that the provided root namespace must be non-reloadable, while allowing autoloaded constants within that namespace to be reloadable. This means that if you associate the `app/api` directory with an existing `Api` module, the module itself should not be reloadable. However, if the project defines and autoloads the `Api::Deliveries` class, that class can be reloaded.

<a id="markdown-nested-root-directories" name="nested-root-directories"></a>
#### Nested root directories

Root directories are recommended not to be nested; however, Zeitwerk provides support for nested root directories since in frameworks like Rails, both `app/models` and `app/models/concerns` belong to the autoload paths.

Zeitwerk identifies nested root directories and treats them as independent roots. In the given example, `concerns` is not considered a namespace within `app/models`. For instance, consider the following file:

```
app/models/concerns/geolocatable.rb
```

should define `Geolocatable`, not `Concerns::Geolocatable`.

<a id="markdown-implicit-namespaces" name="implicit-namespaces"></a>
### Implicit namespaces

If a namespace consists only of a simple module without any code, there is no need to explicitly define it in a separate file. Zeitwerk automatically creates modules on your behalf for directories without a corresponding Ruby file.

For instance, suppose a project includes an `admin` directory:

```
app/controllers/admin/users_controller.rb -> Admin::UsersController
```

and does not have a file called `admin.rb`, Zeitwerk automatically creates an `Admin` module on your behalf the first time `Admin` is used.

To trigger this behavior, the directory must contain non-ignored Ruby files with the ".rb" extension, either directly or recursively. Otherwise, the directory is ignored. This condition is reevaluated during reloads.

<a id="markdown-explicit-namespaces" name="explicit-namespaces"></a>
### Explicit namespaces

Classes and modules that act as namespaces can also be explicitly defined, though. For instance, consider

```
app/models/hotel.rb         -> Hotel
app/models/hotel/pricing.rb -> Hotel::Pricing
```

There, `app/models/hotel.rb` defines `Hotel`, and thus Zeitwerk does not autovivify a module.

The classes and modules from the namespace are already available in the body of the class or module defining it:

```ruby
class Hotel < ApplicationRecord
  include Pricing # works
  ...
end
```

An explicit namespace must be managed by one single loader. Loaders that reopen namespaces owned by other projects are responsible for loading their constants before setup.

<a id="markdown-collapsing-directories" name="collapsing-directories"></a>
### Collapsing directories

Say some directories in a project exist for organizational purposes only, and you prefer not to have them as namespaces. For example, the `actions` subdirectory in the next example is not meant to represent a namespace, it is there only to group all actions related to bookings:

```
booking.rb                -> Booking
booking/actions/create.rb -> Booking::Create
```

To make it work that way, configure Zeitwerk to collapse said directory:

```ruby
loader.collapse("#{__dir__}/booking/actions")
```

This method accepts an arbitrary number of strings or `Pathname` objects, and also an array of them.

You can pass directories and glob patterns. Glob patterns are expanded when they are added, and again on each reload.

To illustrate usage of glob patterns, if `actions` in the example above is part of a standardized structure, you could use a wildcard:

```ruby
loader.collapse("#{__dir__}/*/actions")
```

<a id="markdown-testing-compliance" name="testing-compliance"></a>
### Testing compliance

When a managed file is loaded, Zeitwerk verifies the expected constant is defined. If it is not, `Zeitwerk::NameError` is raised.

So, an easy way to ensure compliance in the test suite is to eager load the project:

```ruby
begin
  loader.eager_load(force: true)
rescue Zeitwerk::NameError => e
  flunk e.message
else
  assert true
end
```

<a id="markdown-usage" name="usage"></a>
## Usage

<a id="markdown-setup" name="setup"></a>
### Setup

<a id="markdown-generic" name="generic"></a>
#### Generic

Loaders are ready to load code right after calling `setup` on them:

```ruby
loader.setup
```

This method is synchronized and idempotent.

Customization should generally be done before that call. In particular, in the generic interface you may set the root directories from which you want to load files:

```ruby
loader.push_dir(...)
loader.push_dir(...)
loader.setup
```

<a id="markdown-for_gem" name="for_gem"></a>
#### for_gem

`Zeitwerk::Loader.for_gem` is a convenience shortcut for the common case in which a gem has its entry point directly under the `lib` directory:

```
lib/my_gem.rb         # MyGem
lib/my_gem/version.rb # MyGem::VERSION
lib/my_gem/foo.rb     # MyGem::Foo
```

Neither a gemspec nor a version file are technically required, this helper works as long as the code is organized using that standard structure.

Conceptually, `for_gem` translates to:

```ruby
# lib/my_gem.rb

require "zeitwerk"
loader = Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, ".rb")
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.dirname(__FILE__))
```

If the main module references project constants at the top-level, Zeitwerk has to be ready to load them. Their definitions, in turn, may reference other project constants. And this is recursive. Therefore, it is important that the `setup` call happens above the main module definition:

```ruby
# lib/my_gem.rb (main file)

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module MyGem
  # Since the setup has been performed, at this point we are already able
  # to reference project constants, in this case MyGem::MyLogger.
  include MyLogger
end
```

Due to technical reasons, the entry point of the gem has to be loaded with `Kernel#require`, which is the standard way to load a gem. Loading that file with `Kernel#load` or `Kernel#require_relative` won't generally work.

`Zeitwerk::Loader.for_gem` is idempotent when invoked from the same file, to support gems that want to reload (unlikely).

If the entry point of your gem lives in a subdirectory of `lib` because it is reopening a namespace defined somewhere else, please use the generic API to setup the loader, and make sure you check the section [_Reopening third-party namespaces_](#reopening-third-party-namespaces) down below.

Loaders returned by `Zeitwerk::Loader.for_gem` issue warnings if `lib` has extra Ruby files or directories.

For example, if the gem has Rails generators under `lib/generators`, by convention that directory defines a `Generators` Ruby module. If `generators` is just a container for non-autoloadable code and templates, not acting as a project namespace, you need to setup things accordingly.

If the warning is legit, just tell the loader to ignore the offending file or directory:

```ruby
loader.ignore("#{__dir__}/generators")
```

Otherwise, there's a flag to say the extra stuff is OK:

```ruby
Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
```

<a id="markdown-for_gem_extension" name="for_gem_extension"></a>
#### for_gem_extension

Let's suppose you are writing a gem to extend `Net::HTTP` with some niche feature. By [convention](https://guides.rubygems.org/name-your-gem/):

* The gem should be called `net-http-niche_feature`. That is, hyphens for the extended part, a hyphen, and underscores for yours.
* The namespace should be `Net::HTTP::NicheFeature`.
* The entry point should be `lib/net/http/niche_feature.rb`.
* Optionally, the gem could have a top-level `lib/net-http-niche_feature.rb`, but, if defined, that one should have just a `require` call for the entry point.

The top-level file mentioned in the last point is optional. In particular, from

```ruby
gem "net-http-niche_feature"
```

if the hyphenated file does not exist, Bundler notes the conventional hyphenated pattern and issues a `require` for `net/http/niche_feature`.

Gem extensions following the conventions above have a dedicated loader constructor: `Zeitwerk::Loader.for_gem_extension`.

The structure of the gem would be like this:

```ruby
# lib/net-http-niche_feature.rb (optional)

# For technical reasons, this cannot be require_relative.
require "net/http/niche_feature"


# lib/net/http/niche_feature.rb

require "net/http"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem_extension(Net::HTTP)
loader.setup

module Net::HTTP::NicheFeature
  # Since the setup has been performed, at this point we are already able
  # to reference project constants, in this case Net::HTTP::NicheFeature::MyMixin.
  include MyMixin
end


# lib/net/http/niche_feature/version.rb

module Net::HTTP::NicheFeature
  VERSION = "1.0.0"
end
```

`Zeitwerk::Loader.for_gem_extension` expects as argument the namespace being extended, which has to be a non-anonymous class or module object.

If it exists, `lib/net/http/niche_feature/version.rb` is expected to define `Net::HTTP::NicheFeature::VERSION`.

Due to technical reasons, the entry point of the gem has to be loaded with `Kernel#require`. Loading that file with `Kernel#load` or `Kernel#require_relative` won't generally work. This is important if you load the entry point from the optional hyphenated top-level file.

`Zeitwerk::Loader.for_gem_extension` is idempotent when invoked from the same file, to support gems that want to reload (unlikely).

<a id="markdown-autoloading" name="autoloading"></a>
### Autoloading

After `setup`, you are able to reference classes and modules from the project without issuing `require` calls for them. They are all available everywhere, autoloading loads them on demand. This works even if the reference to the class or module is first hit in client code, outside your project.

Let's revisit the example above:

```ruby
# lib/my_gem.rb (main file)

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module MyGem
  include MyLogger # (*)
end
```

That works, and there is no `require "my_gem/my_logger"`. When `(*)` is reached, Zeitwerk seamlessly autoloads `MyGem::MyLogger`.

If autoloading a file does not define the expected class or module, Zeitwerk raises `Zeitwerk::NameError`, which is a subclass of `NameError`.

<a id="markdown-eager-loading" name="eager-loading"></a>
### Eager loading

Zeitwerk instances are able to eager load their managed files:

```ruby
loader.eager_load
```

That skips [ignored files and directories](#ignoring-parts-of-the-project).

In gems, the method needs to be invoked after the main namespace has been defined, as shown in [Synopsis](#synopsis).

Eager loading is synchronized and idempotent.

Attempting to eager load without previously calling `setup` raises `Zeitwerk::SetupRequired`.

<a id="markdown-eager-load-exclusions" name="eager-load-exclusions"></a>
#### Eager load exclusions

 You can tell Zeitwerk that certain files or directories are autoloadable, but should not be eager loaded:

```ruby
db_adapters = "#{__dir__}/my_gem/db_adapters"
loader.do_not_eager_load(db_adapters)
loader.setup
loader.eager_load # won't eager load the database adapters
```

However, that can be overridden with `force`:

```ruby
loader.eager_load(force: true) # database adapters are eager loaded
```

Which may be handy if the project eager loads in the test suite to [ensure project layout compliance](#testing-compliance).

The `force` flag does not affect ignored files and directories, those are still ignored.

<a id="markdown-eager-load-directories" name="eager-load-directories"></a>
#### Eager load directories

The method `Zeitwerk::Loader#eager_load_dir` eager loads a given directory, recursively:

```ruby
loader.eager_load_dir("#{__dir__}/custom_web_app/routes")
```

This is useful when the loader is not eager loading the entire project, but you still need some subtree to be loaded for things to function properly.

Both strings and `Pathname` objects are supported as arguments. If the argument is not a directory managed by the receiver, the method raises `Zeitwerk::Error`.

[Eager load exclusions](#eager-load-exclusions), [ignored files and directories](#ignoring-parts-of-the-project), and [shadowed files](#shadowed-files) are not eager loaded.

`Zeitwerk::Loader#eager_load_dir` is idempotent, but compatible with reloading. If you eager load a directory and then reload, eager loading that directory will load its (current) contents again.

The method checks if a regular eager load was already executed, in which case it returns fast.

Nested root directories which are descendants of the argument are skipped. Those subtrees are considered to be conceptually apart.

Attempting to eager load a directory without previously calling `setup` raises `Zeitwerk::SetupRequired`.

<a id="markdown-eager-load-namespaces" name="eager-load-namespaces"></a>
#### Eager load namespaces

The method `Zeitwerk::Loader#eager_load_namespace` eager loads a given namespace, recursively:

```ruby
loader.eager_load_namespace(MyApp::Routes)
```

This is useful when the loader is not eager loading the entire project, but you still need some namespace to be loaded for things to function properly.

The argument has to be a class or module object and the method raises `Zeitwerk::Error` otherwise.

If the namespace is spread over multiple directories in the receiver's source tree, they are all eager loaded. For example, if you have a structure like

```
root_dir1/my_app/routes
root_dir2/my_app/routes
root_dir3/my_app/routes
```

where `root_dir{1,2,3}` are root directories, eager loading `MyApp::Routes` will eager load the contents of the three corresponding directories.

There might exist external source trees implementing part of the namespace. This happens routinely, because top-level constants are stored in the globally shared `Object`. It happens also when deliberately [reopening third-party namespaces](#reopening-third-party-namespaces). Such external code is not eager loaded, the implementation is carefully scoped to what the receiver manages to avoid side-effects elsewhere.

This method is flexible about what it accepts. Its semantics have to be interpreted as: "_If_ you manage this namespace, or part of this namespace, please eager load what you got". In particular, if the receiver does not manage the namespace, it will simply do nothing, this is not an error condition.

[Eager load exclusions](#eager-load-exclusions), [ignored files and directories](#ignoring-parts-of-the-project), and [shadowed files](#shadowed-files) are not eager loaded.

`Zeitwerk::Loader#eager_load_namespace` is idempotent, but compatible with reloading. If you eager load a namespace and then reload, eager loading that namespace will load its (current) descendants again.

The method checks if a regular eager load was already executed, in which case it returns fast.

If root directories are assigned to custom namespaces, the method behaves as you'd expect, according to the namespacing relationship between the custom namespace and the argument.

Attempting to eager load a namespace without previously calling `setup` raises `Zeitwerk::SetupRequired`.

<a id="markdown-eager-load-namespaces-shared-by-several-loaders" name="eager-load-namespaces-shared-by-several-loaders"></a>
#### Eager load namespaces shared by several loaders

The method `Zeitwerk::Loader.eager_load_namespace` broadcasts `eager_load_namespace` to all loaders.

```ruby
Zeitwerk::Loader.eager_load_namespace(MyFramework::Routes)
```

This may be handy, for example, if a framework supports plugins and a shared namespace needs to be eager loaded for the framework to function properly.

Please, note that loaders only eager load namespaces they manage, as documented above. Therefore, this method does not allow you to eager load namespaces not managed by Zeitwerk loaders.

This method does not require that all registered loaders have `setup` already invoked, since that is out of your control. If there's any in that state, it is simply skipped.

<a id="markdown-global-eager-load" name="global-eager-load"></a>
#### Global eager load

If you want to eager load yourself and all dependencies that use Zeitwerk, you can broadcast the `eager_load` call to all instances:

```ruby
Zeitwerk::Loader.eager_load_all
```

This may be handy in top-level services, like web applications.

Note that thanks to idempotence `Zeitwerk::Loader.eager_load_all` won't eager load twice if any of the instances already eager loaded.

This method does not accept the `force` flag, since in general it wouldn't be a good idea to force eager loading in 3rd party code.

This method does not require that all registered loaders have `setup` already invoked, since that is out of your control. If there's any in that state, it is simply skipped.

<a id="markdown-loading-individual-files" name="loading-individual-files"></a>
### Loading individual files

The method `Zeitwerk::Loader#load_file` loads an individual Ruby file:

```ruby
loader.load_file("#{__dir__}/custom_web_app/routes.rb")
```

This is useful when the loader is not eager loading the entire project, but you still need an individual file to be loaded for things to function properly.

Both strings and `Pathname` objects are supported as arguments. The method raises `Zeitwerk::Error` if the argument is not a Ruby file, is [ignored](#ignoring-parts-of-the-project), is [shadowed](#shadowed-files), or is not managed by the receiver.

`Zeitwerk::Loader#load_file` is idempotent, but compatible with reloading. If you load a file and then reload, a new call will load its (current) contents again.

If you want to eager load a directory, `Zeitwerk::Loader#eager_load_dir` is more efficient than invoking `Zeitwerk::Loader#load_file` on its files.

<a id="markdown-reloading" name="reloading"></a>
### Reloading

<a id="markdown-configuration-and-usage" name="configuration-and-usage"></a>
#### Configuration and usage

Zeitwerk is able to reload code, but you need to enable this feature:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.enable_reloading # you need to opt-in before setup
loader.setup
...
loader.reload
```

There is no way to undo this, either you want to reload or you don't.

Enabling reloading after setup raises `Zeitwerk::Error`. Attempting to reload without having it enabled raises `Zeitwerk::ReloadingDisabledError`. Attempting to reload without previously calling `setup` raises `Zeitwerk::SetupRequired`.

Generally speaking, reloading is useful while developing running services like web applications. Gems that implement regular libraries, so to speak, or services running in testing or production environments, won't normally have a use case for reloading. If reloading is not enabled, Zeitwerk is able to use less memory.

Reloading removes the currently loaded classes and modules and resets the loader so that it will pick whatever is in the file system now.

It is important to highlight that this is an instance method. Don't worry about project dependencies managed by Zeitwerk, their loaders are independent.

<a id="markdown-thread-safety" name="thread-safety"></a>
#### Thread-safety

In order to reload safely, no other thread can be autoloading or reloading concurrently. Client code is responsible for this coordination.

For example, a web framework that serves each request in its own thread and has reloading enabled could create a read-write lock on boot like this:

```ruby
require "concurrent/atomic/read_write_lock"

MyFramework::RELOAD_RW_LOCK = Concurrent::ReadWriteLock.new
```

You acquire the lock for reading for serving each individual request:

```ruby
MyFramework::RELOAD_RW_LOCK.with_read_lock do
  serve(request)
end
```

Then, when a reload is triggered, just acquire the lock for writing in order to execute the method call safely:

```ruby
MyFramework::RELOAD_RW_LOCK.with_write_lock do
  loader.reload
end
```

On reloading, client code has to update anything that would otherwise be storing a stale object. For example, if the routing layer of a web framework stores reloadable controller class objects or instances in internal structures, on reload it has to refresh them somehow, possibly reevaluating routes.

<a id="markdown-inflection" name="inflection"></a>
### Inflection

Each individual loader needs an inflector to figure out which constant path would a given file or directory map to. Zeitwerk ships with two basic inflectors, and you can define your own.

<a id="markdown-zeitwerkinflector" name="zeitwerkinflector"></a>
#### Zeitwerk::Inflector

Each loader instantiated with `Zeitwerk::Loader.new` has an inflector of this type by default.

This is a very basic inflector that converts snake case to camel case:

```
user             -> User
users_controller -> UsersController
html_parser      -> HtmlParser
```

The camelize logic can be overridden easily for individual basenames:

```ruby
loader.inflector.inflect(
  "html_parser"   => "HTMLParser",
  "mysql_adapter" => "MySQLAdapter"
)
```

The `inflect` method can be invoked several times if you prefer this other style:

```ruby
loader.inflector.inflect "html_parser" => "HTMLParser"
loader.inflector.inflect "mysql_adapter" => "MySQLAdapter"
```

Overrides have to match exactly directory or file (without extension) _basenames_. For example, if you configure

```ruby
loader.inflector.inflect("xml" => "XML")
```

then the following constants are expected:

```
xml.rb         -> XML
foo/xml        -> Foo::XML
foo/bar/xml.rb -> Foo::Bar::XML
```

As you see, any directory whose basename is exactly `xml`, and any file whose basename is exactly `xml.rb` are expected to define the constant `XML` in the corresponding namespace. On the other hand, partial matches are ignored. For example, `xml_parser.rb` would be inflected as `XmlParser` because `xml_parser` is not equal to `xml`. You'd need an additional override:

```ruby
loader.inflector.inflect(
  "xml"        => "XML",
  "xml_parser" => "XMLParser"
)
```

If you need more flexibility, you can define a custom inflector, as explained down below.

Overrides need to be configured before calling `setup`.

The inflectors of different loaders are independent of each other. There are no global inflection rules or global configuration that can affect this inflector. It is deterministic.

<a id="markdown-zeitwerkgeminflector" name="zeitwerkgeminflector"></a>
#### Zeitwerk::GemInflector

Each loader instantiated with `Zeitwerk::Loader.for_gem` has an inflector of this type by default.

This inflector is like the basic one, except it expects `lib/my_gem/version.rb` to define `MyGem::VERSION`.

The inflectors of different loaders are independent of each other. There are no global inflection rules or global configuration that can affect this inflector. It is deterministic.

<a id="markdown-zeitwerknullinflector" name="zeitwerknullinflector"></a>
#### Zeitwerk::NullInflector

This is an experimental inflector that simply returns its input unchanged.

```ruby
loader.inflector = Zeitwerk::NullInflector.new
```

In a project using this inflector, the names of files and directories are equal to the constants they define:

```
User.rb       -> User
HTMLParser.rb -> HTMLParser
Admin/Role.rb -> Admin::Role
```

Point is, you think less. Names that typically need custom configuration like acronyms no longer require your attention. What you see is what you get, simple.

This inflector is experimental since Ruby usually goes for snake case in files and directories. But hey, if you fancy giving it a whirl, go for it!

The null inflector cannot be used in Rails applications because the `main` autoloader also manages engines. However, you could subclass the default inflector and override `camelize` to return the basename untouched if it starts with an uppercase letter. Generators would not create the expected file names, but you could still experiment to see how far this approach takes you.

In case-insensitive file systems, this inflector works as long as directory listings return the expected strings. Zeitwerk lists directories using Ruby APIs like `Dir.children` or `Dir.entries`.

<a id="markdown-custom-inflector" name="custom-inflector"></a>
#### Custom inflector

The inflectors that ship with Zeitwerk are deterministic and simple. But you can configure your own:

```ruby
# frozen_string_literal: true

class MyInflector < Zeitwerk::Inflector
  def camelize(basename, abspath)
    if basename =~ /\Ahtml_(.*)/
      "HTML" + super($1, abspath)
    else
      super
    end
  end
end
```

The first argument, `basename`, is a string with the basename of the file or directory to be inflected. In the case of a file, without extension. In the case of a directory, without trailing slash. The inflector needs to return this basename inflected. Therefore, a simple constant name without colons.

The second argument, `abspath`, is a string with the absolute path to the file or directory in case you need it to decide how to inflect the basename. Paths to directories don't have trailing slashes.

Then, assign the inflector:

```ruby
loader.inflector = MyInflector.new
```

This needs to be done before calling `setup`.

If a custom inflector definition in a gem takes too much space in the main file, you can extract it. For example, this is a simple pattern:

```ruby
# lib/my_gem/inflector.rb
module MyGem
  class Inflector < Zeitwerk::GemInflector
    ...
  end
end

# lib/my_gem.rb
require "zeitwerk"
require_relative "my_gem/inflector"

loader = Zeitwerk::Loader.for_gem
loader.inflector = MyGem::Inflector.new(__FILE__)
loader.setup

module MyGem
  # ...
end
```

Since `MyGem` is referenced before the namespace is defined in the main file, it is important to use this style:

```ruby
# Correct, effectively defines MyGem.
module MyGem
  class Inflector < Zeitwerk::GemInflector
    # ...
  end
end
```

instead of:

```ruby
# Raises uninitialized constant MyGem (NameError).
class MyGem::Inflector < Zeitwerk::GemInflector
  # ...
end
```

<a id="markdown-callbacks" name="callbacks"></a>
### Callbacks

<a id="markdown-the-on_setup-callback" name="the-on_setup-callback"></a>
#### The on_setup callback

The `on_setup` callback is fired on setup and on each reload:

```ruby
loader.on_setup do
  # Ready to autoload here.
end
```

Multiple `on_setup` callbacks are supported, and they run in order of definition.

If `setup` was already executed, the callback is fired immediately.

<a id="markdown-the-on_load-callback" name="the-on_load-callback"></a>
#### The on_load callback

The usual place to run something when a file is loaded is the file itself. However, sometimes you'd like to be called, and this is possible with the `on_load` callback.

For example, let's imagine this class belongs to a Rails application:

```ruby
class SomeApiClient
  class << self
    attr_accessor :endpoint
  end
end
```

With `on_load`, it is easy to schedule code at boot time that initializes `endpoint` according to the configuration:

```ruby
# config/environments/development.rb
loader.on_load("SomeApiClient") do |klass, _abspath|
  klass.endpoint = "https://api.dev"
end

# config/environments/production.rb
loader.on_load("SomeApiClient") do |klass, _abspath|
  klass.endpoint = "https://api.prod"
end
```

Some uses cases:

* Doing something with a reloadable class or module in a Rails application during initialization, in a way that plays well with reloading. As in the previous example.
* Delaying the execution of the block until the class is loaded for performance.
* Delaying the execution of the block until the class is loaded because it follows the adapter pattern and better not to load the class if the user does not need it.

`on_load` gets a target constant path as a string (e.g., "User", or "Service::NotificationsGateway"). When fired, its block receives the stored value, and the absolute path to the corresponding file or directory as a string. The callback is executed every time the target is loaded. That includes reloads.

Multiple callbacks on the same target are supported, and they run in order of definition.

The block is executed once the loader has loaded the target. In particular, if the target was already loaded when the callback is defined, the block won't run. But if you reload and load the target again, then it will. Normally, you'll want to define `on_load` callbacks before `setup`.

Defining a callback for a target not managed by the receiver is not an error, the block simply won't ever be executed.

It is also possible to be called when any constant managed by the loader is loaded:

```ruby
loader.on_load do |cpath, value, abspath|
  # ...
end
```

The block gets the constant path as a string (e.g., "User", or "Foo::VERSION"), the value it stores (e.g., the class object stored in `User`, or "2.5.0"), and the absolute path to the corresponding file or directory as a string.

Multiple callbacks like these are supported, and they run in order of definition.

There are use cases for this last catch-all callback, but they are rare. If you just need to understand how things are being loaded for debugging purposes, please remember that `Zeitwerk::Loader#log!` logs plenty of information.

If both types of callbacks are defined, the specific ones run first.

Since `on_load` callbacks are executed right after files are loaded, even if the loading context seems to be far away, in practice **the block is subject to [circular dependencies](#beware-of-circular-dependencies)**. As a rule of thumb, as far as loading order and its interdependencies is concerned, you have to program as if the block was executed at the bottom of the file just loaded.

<a id="markdown-the-on_unload-callback" name="the-on_unload-callback"></a>
#### The on_unload callback

When reloading is enabled, you may occasionally need to execute something before a certain autoloaded class or module is unloaded. The `on_unload` callback allows you to do that.

For example, let's imagine that a `Country` class fetches a list of countries and caches them when it is loaded. You might want to clear that cache if unloaded:

```ruby
loader.on_unload("Country") do |klass, _abspath|
  klass.clear_cache
end
```

`on_unload` gets a target constant path as a string (e.g., "User", or "Service::NotificationsGateway"). When fired, its block receives the stored value, and the absolute path to the corresponding file or directory as a string. The callback is executed every time the target is unloaded.

`on_unload` blocks are executed before the class is unloaded, but in the middle of unloading, which happens in an unspecified order. Therefore, **that callback should not refer to any reloadable constant because there is no guarantee the constant works there**. Those blocks should rely on objects only, as in the example above, or regular constants not managed by the loader. This remark is transitive, applies to any methods invoked within the block.

Multiple callbacks on the same target are supported, and they run in order of definition.

Defining a callback for a target not managed by the receiver is not an error, the block simply won't ever be executed.

It is also possible to be called when any constant managed by the loader is unloaded:

```ruby
loader.on_unload do |cpath, value, abspath|
  # ...
end
```

The block gets the constant path as a string (e.g., "User", or "Foo::VERSION"), the value it stores (e.g., the class object stored in `User`, or "2.5.0"), and the absolute path to the corresponding file or directory as a string.

Multiple callbacks like these are supported, and they run in order of definition.

If both types of callbacks are defined, the specific ones run first.

<a id="markdown-technical-details" name="technical-details"></a>
#### Technical details

Zeitwerk uses the word "unload" to ease communication and for symmetry with `on_load`. However, in Ruby you cannot unload things for real. So, when does `on_unload` technically happen?

When unloading, Zeitwerk issues `Module#remove_const` calls. Classes and modules are no longer reachable through their constants, and `on_unload` callbacks are executed right before those calls.

Technically, though, the objects themselves are still alive, but if everything is used as expected and they are not stored in any non-reloadable place (don't do that), they are ready for garbage collection, which is when the real unloading happens.

<a id="markdown-logging" name="logging"></a>
### Logging

Zeitwerk is silent by default, but you can ask loaders to trace their activity. Logging is meant just for troubleshooting, shouldn't normally be enabled.

The `log!` method is a quick shortcut to let the loader log to `$stdout`:

```
loader.log!
```

If you want more control, a logger can be configured as a callable

```ruby
loader.logger = method(:puts)
loader.logger = ->(msg) { ... }
```

as well as anything that responds to `debug`:

```ruby
loader.logger = Logger.new($stderr)
loader.logger = Rails.logger
```

In both cases, the corresponding methods are going to be passed exactly one argument with the message to be logged.

It is also possible to set a global default this way:

```ruby
Zeitwerk::Loader.default_logger = method(:puts)
```

If there is a logger configured, you'll see traces when autoloads are set, files loaded, and modules autovivified. While reloading, removed autoloads and unloaded objects are also traced.

As a curiosity, if your project has namespaces you'll notice in the traces Zeitwerk sets autoloads for _directories_. This allows descending into subdirectories on demand, thus avoiding unnecessary tree walks.

<a id="markdown-loader-tag" name="loader-tag"></a>
#### Loader tag

Loaders have a tag that is printed in traces in order to be able to distinguish them in globally logged activity:

```
Zeitwerk@9fa54b: autoload set for User, to be loaded from ...
```

By default, a random tag like the one above is assigned, but you can change it:

```
loader.tag = "grep_me"
```

The tag of a loader returned by `for_gem` is the basename of the root file without extension:

```
Zeitwerk@my_gem: constant MyGem::Foo loaded from ...
```

<a id="markdown-ignoring-parts-of-the-project" name="ignoring-parts-of-the-project"></a>
### Ignoring parts of the project

Zeitwerk ignores automatically any file or directory whose name starts with a dot, and any files that do not have the extension ".rb".

However, sometimes it might still be convenient to tell Zeitwerk to completely ignore some particular Ruby file or directory. That is possible with `ignore`, which accepts an arbitrary number of strings or `Pathname` objects, and also an array of them.

You can ignore file names, directory names, and glob patterns. Glob patterns are expanded when they are added and again on each reload.

There is an edge case related to nested root directories. Conceptually, root directories are independent source trees. If you ignore a parent of a nested root directory, the nested root directory is not affected. You need to ignore it explicitly if you want it ignored too.

Let's see some use cases.

<a id="markdown-use-case-files-that-do-not-follow-the-conventions" name="use-case-files-that-do-not-follow-the-conventions"></a>
#### Use case: Files that do not follow the conventions

Let's suppose that your gem decorates something in `Kernel`:

```ruby
# lib/my_gem/core_ext/kernel.rb

Kernel.module_eval do
  # ...
end
```

`Kernel` is already defined by Ruby so the module cannot be autoloaded. Also, that file does not define a constant path after the path name. Therefore, Zeitwerk should not process it at all.

The extension can still coexist with the rest of the project, you only need to tell Zeitwerk to ignore it:

```ruby
kernel_ext = "#{__dir__}/my_gem/core_ext/kernel.rb"
loader.ignore(kernel_ext)
loader.setup
```

You can also ignore the whole directory:

```ruby
core_ext = "#{__dir__}/my_gem/core_ext"
loader.ignore(core_ext)
loader.setup
```

Now, that file has to be loaded manually with `require` or `require_relative`:

```ruby
require_relative "my_gem/core_ext/kernel"
```

and you can do that anytime, before configuring the loader, or after configuring the loader, does not matter.

<a id="markdown-use-case-the-adapter-pattern" name="use-case-the-adapter-pattern"></a>
#### Use case: The adapter pattern

Another use case for ignoring files is the adapter pattern.

Let's imagine your project talks to databases, supports several, and has adapters for each one of them. Those adapters may have top-level `require` calls that load their respective drivers:

```ruby
# my_gem/db_adapters/postgresql.rb
require "pg"
```

but you don't want your users to install them all, only the one they are going to use.

On the other hand, if your code is eager loaded by you or a parent project (with `Zeitwerk::Loader.eager_load_all`), those `require` calls are going to be executed. Ignoring the adapters prevents that:

```ruby
db_adapters = "#{__dir__}/my_gem/db_adapters"
loader.ignore(db_adapters)
loader.setup
```

The chosen adapter, then, has to be loaded by hand somehow:

```ruby
require "my_gem/db_adapters/#{config[:db_adapter]}"
```

Note that since the directory is ignored, the required adapter can instantiate another loader to manage its subtree, if desired. Such loader would coexist with the main one just fine.

<a id="markdown-use-case-test-files-mixed-with-implementation-files" name="use-case-test-files-mixed-with-implementation-files"></a>
#### Use case: Test files mixed with implementation files

There are project layouts that put implementation files and test files together. To ignore the test files, you can use a glob pattern like this:

```ruby
tests = "#{__dir__}/**/*_test.rb"
loader.ignore(tests)
loader.setup
```

<a id="markdown-shadowed-files" name="shadowed-files"></a>
### Shadowed files

In Ruby, if you have several files called `foo.rb` in different directories of `$LOAD_PATH` and execute

```ruby
require "foo"
```

the first one found gets loaded, and the rest are ignored.

Zeitwerk behaves in a similar way. If `foo.rb` is present in several root directories (at the same namespace level), the constant `Foo` is autoloaded from the first one, and the rest of the files are not evaluated. If logging is enabled, you'll see something like

```
file #{file} is ignored because #{previous_occurrence} has precedence
```

(This message is not public interface and may change, you cannot rely on that exact wording.)

Even if there's only one `foo.rb`, if the constant `Foo` is already defined when Zeitwerk finds `foo.rb`, then the file is ignored too. This could happen if `Foo` was defined by a dependency, for example. If logging is enabled, you'll see something like

```
file #{file} is ignored because #{constant_path} is already defined
```

(This message is not public interface and may change, you cannot rely on that exact wording.)

Shadowing only applies to Ruby files, namespace definition can be spread over multiple directories. And you can also reopen third-party namespaces if done [orderly](#reopening-third-party-namespaces).

<a id="markdown-edge-cases" name="edge-cases"></a>
### Edge cases

[Explicit namespaces](#explicit-namespaces) like `Trip` here:

```ruby
# trip.rb
class Trip
  include Geolocation
end

# trip/geolocation.rb
module Trip::Geolocation
  ...
end
```

have to be defined with the `class`/`module` keywords, as in the example above.

For technical reasons, raw constant assignment is not supported:

```ruby
# trip.rb
Trip = Class { ...}        # NOT SUPPORTED
Trip = Struct.new { ... }  # NOT SUPPORTED
Trip = Data.define { ... } # NOT SUPPORTED
```

This only affects explicit namespaces, those idioms work well for any other ordinary class or module.

<a id="markdown-beware-of-circular-dependencies" name="beware-of-circular-dependencies"></a>
### Beware of circular dependencies

In Ruby, you can't have certain top-level circular dependencies. Take for example:

```ruby
# c.rb
class C < D
end

# d.rb
class D
  C
end
```

In order to define `C`, you need to load `D`. However, the body of `D` refers to `C`.

Circular dependencies like those do not work in plain Ruby, and therefore do not work in projects managed by Zeitwerk either.

<a id="markdown-reopening-third-party-namespaces" name="reopening-third-party-namespaces"></a>
### Reopening third-party namespaces

Projects managed by Zeitwerk can work with namespaces defined by third-party libraries. However, they have to be loaded in memory before calling `setup`.

For example, let's imagine you're writing a gem that implements an adapter for [Active Job](https://guides.rubyonrails.org/active_job_basics.html) that uses AwesomeQueue as backend. By convention, your gem has to define a class called `ActiveJob::QueueAdapters::AwesomeQueue`, and it has to do so in a file with a matching path:

```ruby
# lib/active_job/queue_adapters/awesome_queue.rb
module ActiveJob
  module QueueAdapters
    class AwesomeQueue
      # ...
    end
  end
end
```

It is very important that your gem _reopens_ the modules `ActiveJob` and `ActiveJob::QueueAdapters` instead of _defining_ them. Because their proper definition lives in Active Job. Furthermore, if the project reloads, you do not want any of `ActiveJob` or `ActiveJob::QueueAdapters` to be reloaded.

Bottom line, Zeitwerk should not be managing those namespaces. Active Job owns them and defines them. Your gem needs to _reopen_ them.

In order to do so, you need to make sure those modules are loaded before calling `setup`. For instance, in the entry file for the gem:

```ruby
# Ensure these namespaces are reopened, not defined.
require "active_job"
require "active_job/queue_adapters"

require "zeitwerk"
# By passing the flag, we acknowledge the extra directory lib/active_job
# has to be managed by the loader and no warning has to be issued for it.
loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.setup
```

With that, when Zeitwerk scans the file system and reaches the gem directories `lib/active_job` and `lib/active_job/queue_adapters`, it detects the corresponding modules already exist and therefore understands it does not have to manage them. The loader just descends into those directories. Eventually will reach `lib/active_job/queue_adapters/awesome_queue.rb`, and since `ActiveJob::QueueAdapters::AwesomeQueue` is unknown, Zeitwerk will manage it. Which is what happens regularly with the files in your gem. On reload, the namespaces are safe, won't be reloaded. The loader only reloads what it manages, which in this case is the adapter itself.

<a id="markdown-introspection" name="introspection"></a>
### Introspection

<a id="markdown-zeitwerkloaderdirs" name="zeitwerkloaderdirs"></a>
#### `Zeitwerk::Loader#dirs`

The method `Zeitwerk::Loader#dirs` returns an array with the absolute paths of the root directories as strings:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(Pathname.new("/foo"))
loader.dirs # => ["/foo"]
```

This method accepts an optional `namespaces` keyword argument. If truthy, the method returns a hash table instead. Keys are the absolute paths of the root directories as strings. Values are their corresponding namespaces, class or module objects:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(Pathname.new("/foo"))
loader.push_dir(Pathname.new("/bar"), namespace: Bar)
loader.dirs(namespaces: true) # => { "/foo" => Object, "/bar" => Bar }
```

By default, ignored root directories are filtered out. If you want them included, please pass `ignored: true`.

These collections are read-only. Please add to them with `Zeitwerk::Loader#push_dir`.

<a id="markdown-zeitwerkloadercpath_expected_at" name="zeitwerkloadercpath_expected_at"></a>
#### `Zeitwerk::Loader#cpath_expected_at`

Given a path as a string or `Pathname` object, `Zeitwerk::Loader#cpath_expected_at` returns a string with the corresponding expected constant path.

Some examples, assuming that `app/models` is a root directory:

```ruby
loader.cpath_expected_at("app/models")                  # => "Object"
loader.cpath_expected_at("app/models/user.rb")          # => "User"
loader.cpath_expected_at("app/models/hotel")            # => "Hotel"
loader.cpath_expected_at("app/models/hotel/billing.rb") # => "Hotel::Billing"
```

If `collapsed` is a collapsed directory:

```ruby
loader.cpath_expected_at("a/b/collapsed/c") # => "A::B::C"
loader.cpath_expected_at("a/b/collapsed")   # => "A::B", edge case
loader.cpath_expected_at("a/b")             # => "A::B"
```

If the argument corresponds to an [ignored file or directory](#ignoring-parts-of-the-project), the method returns `nil`. Same if the argument is not managed by the loader.

`Zeitwerk::Error` is raised if the given path does not exist:

```ruby
loader.cpath_expected_at("non_existing_file.rb") # => Zeitwerk::Error
```

`Zeitwerk::NameError` is raised if a constant path cannot be derived from it:

```ruby
loader.cpath_expected_at("8.rb") # => Zeitwerk::NameError
```

This method does not parse file contents and does not guarantee files define the returned constant path. It just says which is the _expected_ one.

`Zeitwerk::Loader#cpath_expected_at` is designed to be used with individual paths. If you want to know all the expected constant paths in the project, please use `Zeitwerk::Loader#all_expected_cpaths`, documented next.

<a id="markdown-zeitwerkloaderall_expected_cpaths" name="zeitwerkloaderall_expected_cpaths"></a>
#### `Zeitwerk::Loader#all_expected_cpaths`

The method `Zeitwerk::Loader#all_expected_cpaths` returns a hash that maps the absolute paths of the files and directories managed by the receiver to their expected constant paths.

Ignored files, hidden files, and files whose extension is not ".rb" are not included in the result. Same for directories, hidden or ignored directories are not included in the result. Additionally, directories that contain no files with extension ".rb" (recursively) are also excluded, since those are not considered to represent Ruby namespaces.

For example, if `lib` is the root directory of a gem with the following contents:

```
lib/.DS_Store
lib/my_gem.rb
lib/my_gem/version.rb
lib/my_gem/ignored.rb
lib/my_gem/drivers/unix.rb
lib/my_gem/drivers/windows.rb
lib/my_gem/collapsed/foo.rb
lib/tasks/my_gem.rake
```

`Zeitwerk::Loader#all_expected_cpaths` would return (maybe in a different order):

```ruby
{
  "/.../lib"                           => "Object",
  "/.../lib/my_gem.rb"                 => "MyGem",
  "/.../lib/my_gem"                    => "MyGem",
  "/.../lib/my_gem/version.rb"         => "MyGem::VERSION",
  "/.../lib/my_gem/drivers"            => "MyGem::Drivers",
  "/.../lib/my_gem/drivers/unix.rb"    => "MyGem::Drivers::Unix",
  "/.../lib/my_gem/drivers/windows.rb" => "MyGem::Drivers::Windows",
  "/.../lib/my_gem/collapsed"          => "MyGem"
  "/.../lib/my_gem/collapsed/foo.rb"   => "MyGem::Foo"
}
```

In the previous example we assume `lib/my_gem/ignored.rb` is ignored, and therefore it is not present in the returned hash. Also, `lib/my_gem/collapsed` is a collapsed directory, so the expected namespace at that level is still `MyGem` (this is an edge case).

The file `lib/.DS_Store` is hidden, hence excluded. The directory `lib/tasks` is also not present because it contains no files with extension ".rb".

Directory paths do not have trailing slashes.

The order of the hash entries is undefined.

This method does not parse or execute file contents and does not guarantee files define the corresponding constant paths. It just says which are the _expected_ ones.

<a id="markdown-encodings" name="encodings"></a>
### Encodings

Zeitwerk supports projects whose files and file system are in UTF-8. The encoding of the file system can be checked this way:

```
% ruby -e "puts Encoding.find('filesystem')"
UTF-8
```

The test suite passes on Windows with codepage `Windows-1252` if all the involved absolute paths are ASCII. Other supersets of ASCII may work too, but you have to try.

<a id="markdown-rules-of-thumb" name="rules-of-thumb"></a>
### Rules of thumb

1. Different loaders should manage different directory trees. It is an error condition to configure overlapping root directories in different loaders.

2. Think the mere existence of a file is effectively like writing a `require` call for them, which is executed on demand (autoload) or upfront (eager load).

3. In that line, if two loaders manage files that translate to the same constant in the same namespace, the first one wins, the rest are ignored. Similar to what happens with `require` and `$LOAD_PATH`, only the first occurrence matters.

4. Projects that reopen a namespace defined by some dependency have to ensure said namespace is loaded before setup. That is, the project has to make sure it reopens, rather than defines, the namespace. This is often accomplished by loading (e.g., `require`-ing) the dependency.

5. Objects stored in reloadable constants should not be cached in places that are not reloaded. For example, non-reloadable classes should not subclass a reloadable class, or mixin a reloadable module. Otherwise, after reloading, those classes or module objects would become stale. Referring to constants in dynamic places like method calls or lambdas is fine.

6. In a given process, ideally, there should be at most one loader with reloading enabled. Technically, you can have more, but it may get tricky if one refers to constants managed by the other one. Do that only if you know what you are doing.

<a id="markdown-debuggers" name="debuggers"></a>
### Debuggers

Zeitwerk and [debug.rb](https://github.com/ruby/debug) are fully compatible if CRuby is ≥ 3.1 (see [ruby/debug#558](https://github.com/ruby/debug/pull/558)).

[Byebug](https://github.com/deivid-rodriguez/byebug) is compatible except for an edge case explained in [deivid-rodriguez/byebug#564](https://github.com/deivid-rodriguez/byebug/issues/564). Prior to CRuby 3.1, `debug.rb` has a similar edge incompatibility.

[Break](https://github.com/gsamokovarov/break) is fully compatible.

<a id="markdown-pronunciation" name="pronunciation"></a>
## Pronunciation

"Zeitwerk" is pronounced [this way](http://share.hashref.com/zeitwerk/zeitwerk_pronunciation.mp3).

<a id="markdown-supported-ruby-versions" name="supported-ruby-versions"></a>
## Supported Ruby versions

Zeitwerk works with CRuby 2.5 and above.

On TruffleRuby all is good except for thread-safety. Right now, in TruffleRuby `Module#autoload` does not block threads accessing a constant that is being autoloaded. CRuby prevents such access to avoid concurrent threads from seeing partial evaluations of the corresponding file. Zeitwerk inherits autoloading thread-safety from this property. This is not an issue if your project gets eager loaded, or if you lazy load in single-threaded environments. (See https://github.com/oracle/truffleruby/issues/2431.)

JRuby 9.3.0.0 is almost there. As of this writing, the test suite of Zeitwerk passes on JRuby except for three tests. (See https://github.com/jruby/jruby/issues/6781.)

<a id="markdown-testing" name="testing"></a>
## Testing

In order to run the test suite of Zeitwerk, `cd` into the project root and execute

```
bin/test
```

To run one particular suite, pass its file name as an argument:

```
bin/test test/lib/zeitwerk/test_eager_load.rb
```

Furthermore, the project has a development dependency on [`minitest-focus`](https://github.com/seattlerb/minitest-focus). To run an individual test mark it with `focus`:

```ruby
focus
test "capitalizes the first letter" do
  assert_equal "User", camelize("user")
end
```

and run `bin/test`.

<a id="markdown-motivation" name="motivation"></a>
## Motivation

<a id="markdown-kernelrequire-is-brittle" name="kernelrequire-is-brittle"></a>
### Kernel#require is brittle

Since `require` has global side-effects, and there is no static way to verify that you have issued the `require` calls for code that your file depends on, in practice it is very easy to forget some. That introduces bugs that depend on the load order.

Also, if the project has namespaces, setting things up and getting client code to load things in a consistent way needs discipline. For example, `require "foo/bar"` may define `Foo`, instead of reopen it. That may be a broken window, giving place to superclass mismatches or partially-defined namespaces.

With Zeitwerk, you just name things following conventions and done. Things are available everywhere, and descend is always orderly. Without effort and without broken windows.

<a id="markdown-rails-autoloading-was-brittle" name="rails-autoloading-was-brittle"></a>
### Rails autoloading was brittle

Autoloading in Rails was based on `const_missing` up to Rails 5. That callback lacks fundamental information like the nesting or the resolution algorithm being used. Because of that, Rails autoloading was not able to match Ruby's semantics, and that introduced a [series of issues](https://guides.rubyonrails.org/v5.2/autoloading_and_reloading_constants.html#common-gotchas). Zeitwerk is based on a different technique and fixed Rails autoloading starting with Rails 6.

<a id="markdown-awards" name="awards"></a>
## Awards

Zeitwerk has been awarded an "Outstanding Performance Award" Fukuoka Ruby Award 2022.

<a id="markdown-thanks" name="thanks"></a>
## Thanks

I'd like to thank [@matthewd](https://github.com/matthewd) for the discussions we've had about this topic in the past years, I learned a couple of tricks used in Zeitwerk from him.

Also, would like to thank [@Shopify](https://github.com/Shopify), [@rafaelfranca](https://github.com/rafaelfranca), and [@dylanahsmith](https://github.com/dylanahsmith), for sharing [this PoC](https://github.com/Shopify/autoload_reloader). The technique Zeitwerk uses to support explicit namespaces was copied from that project.

Jean Boussier ([@casperisfine](https://github.com/casperisfine), [@byroot](https://github.com/byroot)) deserves special mention. Jean migrated autoloading in Shopify when Zeitwerk integration in Rails was yet unreleased. His work and positive attitude have been outstanding, and thanks to his feedback the interface and performance of Zeitwerk are way, way better. Kudos man ❤️.

Finally, many thanks to [@schurig](https://github.com/schurig) for recording an [audio file](http://share.hashref.com/zeitwerk/zeitwerk_pronunciation.mp3) with the pronunciation of "Zeitwerk" in perfect German. 💯

<a id="markdown-license" name="license"></a>
## License

Released under the MIT License, Copyright (c) 2019–<i>ω</i> Xavier Noria.
