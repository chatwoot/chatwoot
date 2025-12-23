# 0.1.0

* Introduce `Uber::Option` as a replacement for `Uber::Options::Value`. It is still there, but deprecated.
* New API for `Uber::Builder`: You now add builders to `Uber::Builder::Builders` and simply call that instance while passing in context and args. This allows very simple reusable builders that can be used anywhere.
* `Uber::Options` now uses `Uber::Option`.
* Removing `Uber::Version` as this is done nicely by `Gem::Version`.

# 0.0.15

* `Value#evaluate` is now `#call`. This will make it easier to introduce Null objects.
* Options passed to `::builds` are now wrapped in `Uber::Options::Value` which allows specifying builder _class methods_ using `builds :builder_method`.
* `Builder::class_builder` now accepts an optional context object which is used to `instance_exec` the builder blocks. This allows to share predefined builder blocks between different classes while resolving the constants in the respective class.

# 0.0.14

* Add `inheritable_attr :title, clone: false`. Thanks to @katafrakt.
* When calling `Option::Value#evaluate` with `nil` as context, and the `Value` represents a lambda, the block is called it its original context via `block.call`.

# 0.0.13

* Add proc syntax for builders. This allows using `return` in the block. Thanks to @dutow for implementing this.

# 0.0.12

* Make it run with Ruby 2.2.

# 0.0.11

* Don't clone nil, false, true and symbols in `::inheritable_attr`.

# 0.0.10

* Builders are _not_ inherited to subclasses. This allows instantiating subclasses directly without running builders.

# 0.0.9

* Add `Uber::Builder`.

# 0.0.8

* Add `Uber::Delegates` that provides delegation that can be overridden and called with `super`.

# 0.0.7

* Add `Uber::Callable` and support for it in `Options::Value`.

# 0.0.6

* Fix `Version#>=` partially.

# 0.0.5

* Add `Uber::Version` for simple gem version deciders.

# 0.0.4

* Fix a bug where `dynamic: true` wouldn't invoke a method but try to run it as a block.

# 0.0.3

* Add `Options` and `Options::Value´ for abstracting dynamic options.

# 0.0.2

* Add `::inheritable_attr`.
