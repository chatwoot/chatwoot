# Unreleased v1.23.0.0.0

## Added

- Add `HandleBuilder` class for managing libddwaf configuration and building WAF handles
- Add Error classes:
  - `LibDDWAFError` for libddwaf errors
  - `ConversionError` for conversion errors
  - `InstanceFinalizedError` that is raised when attempting to run methods on finalized instances

## Changed

- Change `Handle` instantiation - now it should be done using `HandleBuilder#build_handle` method
- Change `Context` instantiation - now is should be done using `Handle#build_context` method
- Change configuration of Limits and obfuscation - it is now done when initializing `HandleBuilder`
- Change `Context#run` to return a `Result` object instead of an tuple with code and result

## Removed

- Remove `WAF::Handle#merge` method - the configuration is now handled by `HandleBuilder`

# 2025-02-20 v.1.18.0.0.1

- Fixed memory-leak in `Datadog::AppSec::WAF::Context#run` when non-empty ephemeral data passed

# 2024-10-29 v.1.15.0.0.0

- Update to libddwaf 1.15.0
- Changed `Datadog::AppSec::WAF::Context#run` interface to accommodate ephemeral data ([Breaking change](https://github.com/DataDog/libddwaf/blob/master/CHANGELOG.md#v1150-unstable))

# 2023-09-11 v.1.14.0.0.0

- Update to libddwaf 1.14.0
- Add support for `Float` and `Nil` scalar values when converting from ruby to WAF Object and vice versa.

# 2023-08-29 v.1.11.0.0.0

- Update to libddwaf 1.11.0
- Changed `Datadog::AppSec::WAF::Handle#ruleset_info` to `Datadog::AppSec::WAF::Handle#diagnostics`. (Breaking change)
  The schema of the diagnostics variable can be found [here](https://github.com/DataDog/libddwaf/blob/master/schema/diagnostics.json)
- Changed `Datadog::AppSec::WAF::Result#data` to `Datadog::AppSec::WAF::Result#events`. (Breaking change)
  The schema of the events variable can be found [here](https://github.com/DataDog/libddwaf/blob/master/schema/events.json)

# 2023-08-28 v.1.10.0.0.0

- Update to libddwaf 1.10.0

# 2023-06-13 v.1.9.0.0.1

- Handle invalid encoding
- Ensure strings passed to libddwaf are not clipped inside a code point
- Ensure strings passed to libddwaf are UTF-8

# 2023-05-17 v1.9.0.0.0

- Update to libddwaf 1.9.0
- Support [`custom_rules`](https://github.com/DataDog/libddwaf/pull/154)

# 2023-03-03 v1.8.2.0.0

- Update to libddwaf 1.8.2
- Added Waf::Handle#merge method
- Remove Waf::Handle#update_rule_data and Waf::Handle#toggle_rules methods
- Remove WAF::LibDDWAF.ddwaf_required_rule_data_ids method

# 2023-02-03 v1.7.0.0.0

- Update to libddwaf 1.7.0

# 2023-02-03 v1.6.2.0.0

- Update to libddwaf 1.6.2
- Add specs for the getter functions

# 2023-02-01 v1.5.1.0.1

- Fix incorrect size in input string limit
- Fix object freeing on `update_rule_data` and `toggle_rules`

# 2022-10-04 v1.5.1.0.0

- Update to libddwaf 1.5.1
- Add live rule data update API
- Add live rule toggle API
- Add libddwaf boolean type support
- Add Ruby to libddwaf object conversion limits
- Add Ruby to libddwaf object converter optional coercion of scalars to string
- Add static type checking via RBS+Steep
- Change version to return a string
- Change free function to be passed as config instead of context init argument
- Change result to include action list
- Change return code from action to status
- Change handle and context freeing model from GC-based to explicit
- Fix double-free upon finalization of retained C objects
- Fix context crash by retaining necessary C objects

# 2022-05-20 v1.3.0.2.0

- Fix multibyte string handling
- Support JRuby

# 2022-04-29 v1.3.0.1.0

Promotion of v1.3.0.1.0.beta1 to stable

# 2022-04-25 v1.3.0.1.0.beta1

- Add obfuscator configuration
- Add nested object limit configuration
- Add report ruleset information

# 2022-04-29 v1.3.0.0.0

- Promote v1.3.0.0.0.beta1 to stable

# 2022-04-20 v1.3.0.0.0.beta1

- Update to libddwaf 1.3.0

# 2022-03-18 v1.2.1.0.0.beta1

- Update to libddwaf 1.2.1
- Fix incorrect types for a few binding functions

# 2022-03-04 v1.0.14.2.1.beta1

- Fix incorrect return code
- Fix passing nil in libddwaf object containers

# 2022-02-07 v1.0.14.2.0.beta1

- Change Datadog::Security to Datadog::AppSec

# 2022-02-01 v1.0.14.1.0.beta2

- Add support for Ruby 3.1

# 2021-12-14 v1.0.14.1.0.beta1

- Fix sequential runs on a single context by retaining C input data objects

# 2021-11-24 v1.0.14.0.0.beta1

- Update to libddwaf 1.0.14

# 2021-11-24 v1.0.13.0.0.beta1

- Add ruby platform fallback for unsupported platforms
- Update to libddwaf 1.0.13

# 2021-10-13 v1.0.12.0.0.beta1

- Initial release
