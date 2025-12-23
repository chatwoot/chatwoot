# Release History: opentelemetry-sdk

### v1.10.0 / 2025-10-14

* ADDED: Add span flags support for isRemote property

### v1.9.0 / 2025-09-16

* ADDED: Add record_exception option for in_span

### v1.8.1 / 2025-08-14

- FIXED: Remove patch constraint on Zipkin exporter
- DOCS: Fix Resource merge documentation

### v1.8.0 / 2025-02-25

- ADDED: Support 3.1 Min Version

### v1.7.0 / 2025-02-04

- ADDED: Add compatibility with env OTEL_SDK_DISABLED

### v1.6.0 / 2024-12-04

- ADDED: Add hooks to configure logs

### v1.5.0 / 2024-07-24

- ADDED: Add add_link to span api/sdk
- FIXED: Update `untraced` to suppress logging "Calling finish on an ended Span" warnings

### v1.4.1 / 2024-03-21

- FIXED: ForwardingLogger should forward block param.

### v1.4.0 / 2024-01-25

- ADDED: Add spans to Trace::ExportError

### v1.3.2 / 2024-01-23

- FIXED: Reduce allocations on GraphQL hot paths
- FIXED: Add context to metrics reporting of buffer-full events

### v1.3.1 / 2023-11-02

- FIXED: Spec compliance for span attribute limit
- FIXED: BatchSpanProcessor#force_flush: purge inherited spans even on shutdown

### v1.3.0 / 2023-06-08

- BREAKING CHANGE: Remove support for EoL Ruby 2.7

- ADDED: Remove support for EoL Ruby 2.7
- FIXED: SDK requires opentelemetry-common 0.19.7

### v1.2.1 / 2023-05-30

- FIXED: Untraced only works with parent-based sampler
- DOCS: Improve formatting of usage examples in OpenTelemetry SDK rubydocs

### v1.2.0 / 2022-09-14

- ADDED: Support OTEL_PROPAGATORS=none
- ADDED: Support OTEL*ATTRIBUTE*{COUNT,VALUE_LENGTH}\_LIMIT env vars
- ADDED: Support InstrumentationScope, and update OTLP proto to 0.18.0
- FIXED: SpanLimits setting event attributes length limit

### v1.1.0 / 2022-05-26

- BREAKING CHANGE: This requires upgrading both the SDK and Instrumentation gem in tandem

### v1.0.3 / 2022-05-02

- ADDED: Truncate the strings in an array attribute value if length_limit is configured
- FIXED: Update attribute length limit env var name to match spec
- FIXED: Warning about Struct initialization in Ruby 3.2+
- FIXED: Warn on unsupported otlp transport protocols
- FIXED: Only allow certain types of Numeric values as attribute values.

### v1.0.2 / 2021-12-01

- FIXED: Default span kind
- FIXED: Use monotonic clock where possible

### v1.0.1 / 2021-10-29

- FIXED: Add unexpected error handlign in BSP and OTLP exporter (#995)

### v1.0.0 / 2021-09-29

- (No significant changes)

### v1.0.0.rc3 / 2021-08-12

- BREAKING CHANGE: Remove optional parent_context from in_span
- BREAKING CHANGE: Replace Time.now with Process.clock_gettime
- BREAKING CHANGE: Refactor Baggage to remove Noop\*
- BREAKING CHANGE: Remove unnecessary readers from SDK Tracer
- BREAKING CHANGE: Total order constraint on span.status=
- BREAKING CHANGE: Use auto-generated resource constants in sdk and resource_detectors
- BREAKING CHANGE: Span limits env vars

- ADDED: Add Tracer.non_recording_span to API
- ADDED: Add unnamed tracer warning message
- ADDED: Allow disabling of install messages
- ADDED: Make API's NoopTextMapPropagator private
- ADDED: Use auto-generated resource constants in sdk and resource_detectors
- ADDED: Allow selecting multiple exporter
- ADDED: Add explicit BSP export error
- FIXED: Remove optional parent_context from in_span
- FIXED: Replace Time.now with Process.clock_gettime
- FIXED: Rename cloud.zone to cloud.availability_zone
- FIXED: Improve attribute error messages
- FIXED: Refactor Baggage to remove Noop\*
- FIXED: Support OTEL_SERVICE_NAME env var
- FIXED: Remove unnecessary readers from SDK Tracer
- FIXED: Total order constraint on span.status=
- FIXED: Flakey tracer provider test
- FIXED: Split lock in TracerProvider
- FIXED: Span limits env vars
- FIXED: Prune invalid links
- DOCS: Update docs to rely more on environment variable configuration

### v1.0.0.rc2 / 2021-06-23

- BREAKING CHANGE: Remove optional parent_context from in_span [729](https://github.com/open-telemetry/opentelemetry-ruby/pull/729)
- BREAKING CHANGE: Replace Time.now with Process.clock_gettime [717](https://github.com/open-telemetry/opentelemetry-ruby/pull/717)
- BREAKING CHANGE: Refactor Baggage to remove Noop\* [800](https://github.com/open-telemetry/opentelemetry-ruby/pull/800)
- BREAKING CHANGE: Remove unnecessary readers from SDK Tracer [820](https://github.com/open-telemetry/opentelemetry-ruby/pull/820)
  - Tracer no longer surfaces attribute readers for the name, version, or tracer_provider
- BREAKING CHANGE: Total order constraint on span.status= [805](https://github.com/open-telemetry/opentelemetry-ruby/pull/805)

- ADDED: Add Tracer.non_recording_span to API [799](https://github.com/open-telemetry/opentelemetry-ruby/pull/799)
- ADDED: Add unnamed tracer warning message [830](https://github.com/open-telemetry/opentelemetry-ruby/pull/830)
- ADDED: Allow disabling of install messages [831](https://github.com/open-telemetry/opentelemetry-ruby/pull/831)
- FIXED: Rename cloud.zone to cloud.availability_zone [734](https://github.com/open-telemetry/opentelemetry-ruby/pull/734)
- FIXED: Improve attribute error messages [742](https://github.com/open-telemetry/opentelemetry-ruby/pull/742)
- FIXED: Support OTEL_SERVICE_NAME env var [806]https://github.com/open-telemetry/opentelemetry-ruby/pull/806
- FIXED: Flakey tracer provider test

### v1.0.0.rc1 / 2021-05-21

- BREAKING CHANGE: Remove optional parent_context from in_span
- BREAKING CHANGE: Replace Time.now with Process.clock_gettime

- FIXED: Remove optional parent_context from in_span
- FIXED: Replace Time.now with Process.clock_gettime
- FIXED: Rename cloud.zone to cloud.availability_zone
- FIXED: Improve attribute error messages

### v0.17.0 / 2021-04-22

- BREAKING CHANGE: Replace TextMapInjector/TextMapExtractor pairs with a TextMapPropagator.

  [Check the propagator documentation](https://open-telemetry.github.io/opentelemetry-ruby/) for the new usage.

- ADDED: Add zipkin exporter
- ADDED: Processors validate exporters on init.
- ADDED: Add configurable truncation of span and event attribute values
- ADDED: Add simple 'recording' attr_accessor to InMemorySpanExporter
- FIXED: Typo in error message
- FIXED: Improve configuration error reporting
- FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

- BREAKING CHANGE: Update SDK BaggageManager to match API
- BREAKING CHANGE: Implement Exporter#force_flush

- ADDED: Add force_flush to SDK's TracerProvider
- ADDED: Add k8s node to gcp resource detector
- ADDED: Add console option for OTEL_TRACES_EXPORTER
- ADDED: Span#add_attributes
- ADDED: Implement Exporter#force_flush
- FIXED: Update SDK BaggageManager to match API
- DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

- BREAKING CHANGE: Streamline processor pipeline

- ADDED: Add instrumentation config validation
- FIXED: Streamline processor pipeline
- FIXED: OTEL_TRACE -> OTEL_TRACES env vars
- FIXED: Change limits from 1000 to 128
- FIXED: OTEL_TRACES_EXPORTER and OTEL_PROPAGATORS
- FIXED: Add thread error handling to the BSP
- DOCS: Clarify nil attribute values not allowed

### v0.14.0 / 2021-02-03

- BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

- ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.1 / 2021-02-01

- FIXED: Leaky test
- FIXED: Allow env var override of service.name

### v0.13.0 / 2021-01-29

- BREAKING CHANGE: Remove MILLIS from BatchSpanProcessor vars

- ADDED: Process.runtime resource
- ADDED: Provide default resource in SDK
- ADDED: Add optional attributes to record_exception
- FIXED: Resource.merge consistency
- FIXED: Remove MILLIS from BatchSpanProcessor vars

### v0.12.1 / 2021-01-13

- FIXED: Fix several BatchSpanProcessor errors related to fork safety
- FIXED: Define default value for traceid ratio

### v0.12.0 / 2020-12-24

- ADDED: Structured error handling
- ADDED: Pluggable ID generation
- FIXED: BSP dropped span buffer full reporting
- FIXED: Implement SDK environment variables
- FIXED: Remove incorrect TODO

### v0.11.1 / 2020-12-16

- FIXED: BSP dropped span buffer full reporting

### v0.11.0 / 2020-12-11

- ADDED: Metrics reporting from trace export
- FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

- BREAKING CHANGE: Allow samplers to modify tracestate

- FIXED: Allow samplers to modify tracestate

### v0.9.0 / 2020-11-27

- BREAKING CHANGE: Pass full Context to samplers
- BREAKING CHANGE: Add timeout for force_flush and shutdown

- ADDED: Add OTEL_RUBY_BSP_START_THREAD_ON_BOOT env var
- ADDED: Add timeout for force_flush and shutdown
- FIXED: Signal at batch_size
- FIXED: SDK Span.recording? after finish
- FIXED: Pass full Context to samplers
- DOCS: Add documentation on usage scenarios for span processors

### v0.8.0 / 2020-10-27

- BREAKING CHANGE: Move context/span methods to Trace module
- BREAKING CHANGE: Remove 'canonical' from status codes
- BREAKING CHANGE: Assorted SpanContext fixes

- FIXED: Move context/span methods to Trace module
- FIXED: Remove 'canonical' from status codes
- FIXED: Assorted SpanContext fixes

### v0.7.0 / 2020-10-07

- ADDED: Add service_name setter to configurator
- ADDED: Add service_version setter to configurator
- FIXED: Fork safety for batch processor
- FIXED: Don't generate a span ID unnecessarily
- DOCS: Fix Configurator#add_span_processor
- DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

- BREAKING CHANGE: Rename Resource labels to attributes
- BREAKING CHANGE: Export resource from Span/SpanData instead of library_resource
- BREAKING CHANGE: Rename CorrelationContext to Baggage
- BREAKING CHANGE: Rename Text* to TextMap* (propagators, injectors, extractors)
- BREAKING CHANGE: Rename span.record_error to span.record_exception
- BREAKING CHANGE: Update samplers to match spec
- BREAKING CHANGE: Remove support for lazy event creation

- ADDED: Add OTLP exporter
- ADDED: Add support for OTEL_LOG_LEVEL env var
- FIXED: Rename Resource labels to attributes
- ADDED: Environment variable resource detection
- ADDED: BatchSpanProcessor environment variable support
- FIXED: Remove semver prefix
- FIXED: Docs for array valued attributes
- ADDED: Add hex_trace_id and hex_span_id helpers to SpanData
- FIXED: Fix ProbabilitySampler
- ADDED: Implement GetCorrelations
- FIXED: Change default Sampler to ParentOrElse(AlwaysOn)
- FIXED: Fix probability sampler
