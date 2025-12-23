# 0.0.10

* `Defaults.merge!` will now deprecate non-wrapped `Array` values. The following code is no longer valid (but still works).

        defaults.merge!( list: [1,2] )

    Instead, you need to wrap it in a command like `Variables::Append`.

        defaults.merge!( list: Declarative::Variables::Append( [1,2] ) )

    The reason for this change is to allow all kinds of operations with defaults variables, such as merges, overrides, append, prepend, and so on.

* Introduce `Declarative::Variables.merge` to merge two sets of variables.
* `Defaults` now uses `Variables` for merge/overide operations.

# 0.0.9

* Removing `uber` dependency.

# 0.0.8

* When calling `Schema#defaults` (or `Defaults#merge!`) multiple times, same-named arrays will be joined instead of overridden. This fixes a common problem when merging different default settings.
* Remove `Defaults#[]` and `Defaults#[]=`. This now happens via `#merge!`.

# 0.0.7

* Simplify `Defaults` and remove a warning in Ruby 2.2.3.

# 0.0.6

* `Heritage#call` now accepts a block that allows processing the arguments for every recorded statement before replaying them. This provides a hook to inject or change parameters, e.g. to mark a replay as an inheritance.

# 0.0.5

* Introduce `Schema::build_definition` as a central entry point for building `Definition` without any heritage involved.

# 0.0.4

* Restructured modules, there's always a public `DSL` module now, etc.

# 0.0.3

* Internals, only.

# 0.0.2

* First usable version with `Declarative::Schema` and friends.

TODO: default_nested_class RM
