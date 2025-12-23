# Release History: opentelemetry-api

### v1.7.0 / 2025-09-17

* BREAKING CHANGE: Remove Span APIs for attributes and events

* ADDED: Add record_exception option for in_span
* FIXED: Remove Span APIs for attributes and events

### v1.6.0 / 2025-08-14

- ADDED: Add noop methods on Trace::Span for `attributes` and `events`

### v1.5.0 / 2025-02-20

- ADDED: Support 3.1 Min Version
- FIXED: Use a Fiber attribute for Context

### v1.4.0 / 2024-08-27

- ADDED: Include backtrace first line for better debug info

### v1.3.0 / 2024-07-24

- ADDED: Add add_link to span api/sdk

### v1.2.5 / 2024-02-20

- FIXED: Replace Context stack on clear

### v1.2.4 / 2024-02-06

- FIXED: SystemStackError in Composite Text Map Propagator (#1590)

### v1.2.3 / 2023-09-18

- FIXED: Optimize span and trace ID generation
- FIXED: Small perf improvement to generate_r

### v1.2.2 / 2023-08-15

- FIXED: Patch the issue for frozen string on ruby < 3.0 with string interpolation
- FIXED: Performance regression in_span
- FIXED: In_span performance

### v1.2.1 / 2023-07-29

- DOCS: Describe Tracer#in_span arguments

### v1.2.0 / 2023-06-08

- BREAKING CHANGE: Remove support for EoL Ruby 2.7

- ADDED: Remove support for EoL Ruby 2.7

### v1.1.0 / 2022-09-14

- ADDED: Consistent probability sampler
- FIXED: Get API onto rubocop 1.3

### v1.0.2 / 2022-05-02

- FIXED: Text map propagator extraction should use argument context

### v1.0.1 / 2021-12-01

- FIXED: Deprecate api rack env getter

### v1.0.0 / 2021-09-29

- (No significant changes)

### v1.0.0.rc3 / 2021-08-12

- BREAKING CHANGE: Remove optional parent_context from in_span
- BREAKING CHANGE: Refactor Baggage to remove Noop\*
- BREAKING CHANGE: Total order constraint on span.status=

- ADDED: Add Tracer.non_recording_span to API
- ADDED: Make API's NoopTextMapPropagator private
- FIXED: Remove optional parent_context from in_span
- FIXED: Reduce span allocation in API
- FIXED: Refactor Baggage to remove Noop\*
- FIXED: Total order constraint on span.status=
- FIXED: Return early if carrier is nil
- FIXED: Update context to match spec
- FIXED: Return the original context if the baggage header value is empty
- DOCS: Update docs to rely more on environment variable configuration

### v1.0.0.rc2 / 2021-06-23

- BREAKING CHANGE: Remove optional parent_context from in_span [729](https://github.com/open-telemetry/opentelemetry-ruby/pull/729)
- BREAKING CHANGE: Refactor Baggage to remove Noop\* [800](https://github.com/open-telemetry/opentelemetry-ruby/pull/800)
  - The noop baggage manager has been removed.
  - The baggage management methods are now available through OpenTelemetry::Baggage#method, previously OpenTelemetry.baggage#method
- BREAKING CHANGE: Total order constraint on span.status= [805](https://github.com/open-telemetry/opentelemetry-ruby/pull/805)

  - The OpenTelemetry::Trace::Util::HttpToStatus module has been removed as it was incorrectly setting the span status to OK for codes codes in the range 100..399
  - The HttpToStatus module can be replaced inline as follows `span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response_code.to_i)`
  - The `Status.new(code, description:)` initializer has been hidden in favour of simpler constructors for each status code: `Status.ok`, `Status.error` and `Status.unset`. Each constructor takes an optional description.

- ADDED: Add Tracer.non_recording_span to API [799](https://github.com/open-telemetry/opentelemetry-ruby/pull/799)
- FIXED: Reduce span allocation in API [795](https://github.com/open-telemetry/opentelemetry-ruby/pull/795)
- FIXED: Return early if carrier is nil [835](https://github.com/open-telemetry/opentelemetry-ruby/pull/835)
- FIXED: Update context to match spec [807](https://github.com/open-telemetry/opentelemetry-ruby/pull/807)
  - The `Context.current` setter has been removed and the previously private attach/detach methods are now available as class methods on the context module.

### v1.0.0.rc1 / 2021-05-21

- BREAKING CHANGE: Remove optional parent_context from in_span

- FIXED: Remove optional parent_context from in_span

### v0.17.0 / 2021-04-22

- BREAKING CHANGE: Replace TextMapInjector/TextMapExtractor pairs with a TextMapPropagator.

  [Check the propagator documentation](https://open-telemetry.github.io/opentelemetry-ruby/) for the new usage.

- BREAKING CHANGE: Remove metrics API.

  `OpenTelemetry::Metrics` and all of its behavior removed until spec stabilizes.

- BREAKING CHANGE: Extract instrumentation base from api (#698).

  To take advantage of a base instrumentation class to create your own auto-instrumentation, require and use the `opentelemetry-instrumentation-base` gem.

- ADDED: Default noop tracer for instrumentation
- FIXED: Refactor propagators to add #fields
- FIXED: Remove metrics API
- FIXED: Dynamically upgrade global tracer provider

### v0.16.0 / 2021-03-17

- ADDED: Span#add_attributes
- FIXED: Handle rack env getter edge cases
- DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

- ADDED: Add instrumentation config validation
- DOCS: Clarify nil attribute values not allowed

### v0.14.0 / 2021-02-03

- BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

- ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.0 / 2021-01-29

- ADDED: Add optional attributes to record_exception
- FIXED: Small test fixes.

### v0.12.1 / 2021-01-13

- FIXED: Eliminate warning about Random::DEFAULT on Ruby 3.0

### v0.12.0 / 2020-12-24

- ADDED: Structured error handling

### v0.11.0 / 2020-12-11

- BREAKING CHANGE: Implement tracestate

- ADDED: Implement tracestate
- FIXED: Missing white space from install messages
- FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

- (No significant changes)

### v0.9.0 / 2020-11-27

- (No significant changes)

### v0.8.0 / 2020-10-27

- BREAKING CHANGE: Move context/span methods to Trace module
- BREAKING CHANGE: Remove 'canonical' from status codes
- BREAKING CHANGE: Assorted SpanContext fixes

- ADDED: B3 support
- FIXED: Move context/span methods to Trace module
- FIXED: Remove 'canonical' from status codes
- FIXED: Assorted SpanContext fixes

### v0.7.0 / 2020-10-07

- FIXED: Safely navigate span variable during error cases
- DOCS: Standardize toplevel docs structure and readme
- DOCS: Fix param description in TextMapInjector for Baggage

### v0.6.0 / 2020-09-10

- ADDED: Add support for OTEL_LOG_LEVEL env var
- Documented array valued attributes [#343](https://github.com/open-telemetry/opentelemetry-ruby/pull/343)
- Renamed CorrelationContext to Baggage [#338](https://github.com/open-telemetry/opentelemetry-ruby/pull/338)
- Renamed Text* to TextMap* (propagators) [#335](https://github.com/open-telemetry/opentelemetry-ruby/pull/335)
- Fixed exception semantic conventions (`span.record_error` -> `span.record_exception`) [#333](https://github.com/open-telemetry/opentelemetry-ruby/pull/333)
- Removed support for lazy event creation [#329](https://github.com/open-telemetry/opentelemetry-ruby/pull/329)
  - `name:` named parameter to `span.add_event` becomes first positional argument
  - `Event` class removed from API
- Added `hex_trace_id` and `hex_span_id` helpers to `SpanContext` [#332](https://github.com/open-telemetry/opentelemetry-ruby/pull/332)
- Added `CorrelationContext::Manager.values` method to return correlations as a `Hash` [#323](https://github.com/open-telemetry/opentelemetry-ruby/pull/323)
