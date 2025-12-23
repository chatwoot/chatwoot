# Release History: opentelemetry-exporter-otlp

### v0.31.1 / 2025-10-21

* FIXED: Requires minimum SDK support for new parent_span_is_remote attribute

### v0.31.0 / 2025-10-14

* ADDED: Add span flags support for isRemote property

### v0.30.0 / 2025-02-25

- ADDED: Support 3.1 Min Version

### v0.29.1 / 2024-12-04

- FIXED: Remove WRITE_TIMEOUT_SUPPORTED

### v0.29.0 / 2024-08-27

- ADDED: Add support for mutual TLS.

### v0.28.1 / 2024-07-24

- ADDED: Improve SSL error logging.

### v0.28.0 / 2024-06-19

- ADDED: Bump google_protobuf >=3.18, < 5.a

### v0.27.0 / 2024-04-19

- ADDED: Add stats for serialization time in otlp exporter

### v0.26.3 / 2024-02-01

- FIXED: do not log request failure in backoff?

### v0.26.2 / 2024-01-23

- FIXED: Align endpoint environment variable handling with spec
- FIXED: Require csv for ruby-3.4 compatibility
- FIXED: Add context to metrics reporting of buffer-full events

### v0.26.1 / 2023-07-29

- FIXED: Regenerate v0.20.0 protos
- ADDED: Allow google-protobuf ~> 3.14

### v0.26.0 / 2023-06-13

- ADDED: Use OTLP 0.20.0 protos

### v0.25.0 / 2023-06-01

- BREAKING CHANGE: Remove support for EoL Ruby 2.7

- ADDED: Remove support for EoL Ruby 2.7
- FIXED: Make version available to user agent header #1458

### v0.24.1 / 2023-05-30

- FIXED: Add Ruby 3.2 to CI and do small fix
- FIXED: Adds User-Agent header in OTLP exporter

### v0.24.0 / 2022-09-14

- ADDED: Support InstrumentationScope, and update OTLP proto to 0.18.0
- FIXED: Handle OTLP exporter 404s discretely
- FIXED: `OTEL_EXPORTER_OTLP_ENDPOINT` appends the correct path with a trailing slash
- FIXED: OTLP exporter demo code
- DOCS: Update exporter default compression setting

### v0.23.0 / 2022-06-23

- ADDED: Report bundle size stats in exporter; also don't re-gzip unnecessarily

### v0.22.0 / 2022-06-09

- ADDED: Otlp grpc

### v0.21.3 / 2022-05-12

- (No significant changes)

### v0.21.2 / 2022-01-19

- FIXED: Default scheme for OTLP endpoint
- FIXED: Remove TIMEOUT status from OTLP exporter (#1087)

### v0.21.1 / 2021-12-31

- FIXED: Allow OTLP Exporter compression value of `none`

### v0.21.0 / 2021-12-01

- ADDED: Exporter should use gzip compression by default

### v0.20.6 / 2021-10-29

- FIXED: Add unexpected error handlign in BSP and OTLP exporter (#995)
- FIXED: Handle otlp exporter race condition gzip errors with retry

### v0.20.5 / 2021-09-29

- (No significant changes)

### v0.20.4 / 2021-09-29

- FIXED: OTLP Export Header Format

### v0.20.3 / 2021-08-19

- FIXED: OTLP exporter missing failure metrics

### v0.20.2 / 2021-08-12

- FIXED: Add rescue for OpenSSL errors during export
- DOCS: Update docs to rely more on environment variable configuration

### v0.20.1 / 2021-06-29

- FIXED: Otlp encoding exceptions again

### v0.20.0 / 2021-06-23

- BREAKING CHANGE: Total order constraint on span.status=

- FIXED: Total order constraint on span.status=

### v0.19.0 / 2021-06-03

- ADDED: Add a SSL verify mode option for the OTLP exporter
- FIXED: Handle OTLP exporter encoding exceptions
- DOCS: Remove the OTLP receiver legacy gRPC port(55680) references

### v0.18.0 / 2021-05-21

- BREAKING CHANGE: Replace Time.now with Process.clock_gettime

- FIXED: Replace Time.now with Process.clock_gettime
- FIXED: Rescue missed otlp exporter network errors

### v0.17.0 / 2021-04-22

- ADDED: Add zipkin exporter

### v0.16.0 / 2021-03-17

- BREAKING CHANGE: Implement Exporter#force_flush

- ADDED: Implement Exporter#force_flush
- FIXED: Rescue socket err in otlp exporter to prevent failures unable to connect
- DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

- BREAKING CHANGE: Streamline processor pipeline

- ADDED: Add otlp exporter hooks
- FIXED: Streamline processor pipeline

### v0.14.0 / 2021-02-03

- (No significant changes)

### v0.13.0 / 2021-01-29

- BREAKING CHANGE: Spec compliance for OTLP exporter

- ADDED: Add untraced wrapper to common utils
- FIXED: Spec compliance for OTLP exporter
- FIXED: Conditionally append path to collector endpoint
- FIXED: OTLP path should be /v1/traces
- FIXED: Rename OTLP env vars SPAN -> TRACES

### v0.12.1 / 2021-01-13

- FIXED: Updated protobuf version dependency

### v0.12.0 / 2020-12-24

- (No significant changes)

### v0.11.0 / 2020-12-11

- BREAKING CHANGE: Implement tracestate

- ADDED: Implement tracestate
- ADDED: Metrics reporting from trace export
- FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

- (No significant changes)

### v0.9.0 / 2020-11-27

- BREAKING CHANGE: Add timeout for force_flush and shutdown

- ADDED: Add timeout for force_flush and shutdown
- FIXED: Remove unused kwarg from otlp exporter retry

### v0.8.0 / 2020-10-27

- BREAKING CHANGE: Move context/span methods to Trace module
- BREAKING CHANGE: Remove 'canonical' from status codes
- BREAKING CHANGE: Assorted SpanContext fixes

- FIXED: Move context/span methods to Trace module
- FIXED: Remove 'canonical' from status codes
- FIXED: Add gzip support to OTLP exporter
- FIXED: Assorted SpanContext fixes

### v0.7.0 / 2020-10-07

- FIXED: OTLP parent_span_id should be nil for root
- DOCS: Fix use of add_event in OTLP doc
- DOCS: Standardize toplevel docs structure and readme
- DOCS: Use BatchSpanProcessor in examples

### v0.6.0 / 2020-09-10

- Initial release.
