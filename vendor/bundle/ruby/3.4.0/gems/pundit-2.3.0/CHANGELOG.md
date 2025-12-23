# Pundit

## 2.3.0 (2022-12-19)

### Added

- add support for rubocop-rspec syntax extensions (#745)

## 2.2.0 (2022-02-11)

### Fixed

- Using `policy_class` and a namespaced record now passes only the record when instantiating the policy. (#697, #689, #694, #666)

### Changed

- Require users to explicitly define Scope#resolve in generated policies (#711, #722)

### Deprecated

- Deprecate `include Pundit` in favor of `include Pundit::Authorization` (#621)

## 2.1.1 (2021-08-13)

Friday 13th-release!

Careful! The bugfix below (#626) could break existing code. If you rely on the
return value for `authorize` and namespaced policies you might need to do some
changes.

### Fixed

- `.authorize` and `#authorize` return the instance, even for namespaced
  policies (#626)

### Changed

- Generate application scope with `protected` attr_readers. (#616)

### Removed

- Dropped support for Ruby end-of-life versions: 2.1 and 2.2. (#604)
- Dropped support for Ruby end-of-life versions: 2.3 (#633)
- Dropped support for Ruby end-of-life versions: 2.4, 2.5 and JRuby 9.1 (#676)
- Dropped support for RSpec 2 (#615)

## 2.1.0 (2019-08-14)

### Fixed

- Avoid name clashes with the Error class. (#590)

### Changed

- Return a safer default NotAuthorizedError message. (#583)

## 2.0.1 (2019-01-18)

### Breaking changes

None

### Other changes

- Improve exception handling for `#policy_scope` and `#policy_scope!`. (#550)
- Add `:policy` metadata to RSpec template. (#566)

## 2.0.0 (2018-07-21)

No changes since beta1

## 2.0.0.beta1 (2018-07-04)

### Breaking changes

- Only pass last element of "namespace array" to policy and scope. (#529)
- Raise `InvalidConstructorError` if a policy or policy scope with an invalid constructor is called. (#462)
- Return passed object from `#authorize` method to make chaining possible. (#385)

### Other changes

- Add `policy_class` option to `authorize` to be able to override the policy. (#441)
- Add `policy_scope_class` option to `authorize` to be able to override the policy scope. (#441)
- Fix `param_key` issue when passed an array. (#529)
- Allow specification of a `NilClassPolicy`. (#525)
- Make sure `policy_class` override is called when passed an array. (#475)

- Use `action_name` instead of `params[:action]`. (#419)
- Add `pundit_params_for` method to make it easy to customize params fetching. (#502)

## 1.1.0 (2016-01-14)

- Can retrieve policies via an array of symbols/objects.
- Add autodetection of param key to `permitted_attributes` helper.
- Hide some methods which should not be actions.
- Permitted attributes should be expanded.
- Generator uses `RSpec.describe` according to modern best practices.

## 1.0.1 (2015-05-27)

- Fixed a regression where NotAuthorizedError could not be ininitialized with a string.
- Use `camelize` instead of `classify` for symbol policies to prevent weird pluralizations.

## 1.0.0 (2015-04-19)

- Caches policy scopes and policies.
- Explicitly setting the policy for the controller via `controller.policy = foo` has been removed. Instead use `controller.policies[record] = foo`.
- Explicitly setting the policy scope for the controller via `controller.policy_policy = foo` has been removed. Instead use `controller.policy_scopes[scope] = foo`.
- Add `permitted_attributes` helper to fetch attributes from policy.
- Add `pundit_policy_authorized?` and `pundit_policy_scoped?` methods.
- Instance variables are prefixed to avoid collisions.
- Add `Pundit.authorize` method.
- Add `skip_authorization` and `skip_policy_scope` helpers.
- Better errors when checking multiple permissions in RSpec tests.
- Better errors in case `nil` is passed to `policy` or `policy_scope`.
- Use `inspect` when printing object for better errors.
- Dropped official support for Ruby 1.9.3

## 0.3.0 (2014-08-22)

- Extend the default `ApplicationPolicy` with an `ApplicationPolicy::Scope` (#120)
- Fix RSpec 3 deprecation warnings for built-in matchers (#162)
- Generate blank policy spec/test files for Rspec/MiniTest/Test::Unit in Rails (#138)

## 0.2.3 (2014-04-06)

- Customizable error messages: `#query`, `#record` and `#policy` methods on `Pundit::NotAuthorizedError` (#114)
- Raise a different `Pundit::AuthorizationNotPerformedError` when `authorize` call is expected in controller action but missing (#109)
- Update Rspec matchers for Rspec 3 (#124)

## 0.2.2 (2014-02-07)

- Customize the user to be passed into policies: `pundit_user` (#42)
