# Release History: opentelemetry-common

### v0.23.0 / 2025-10-14

* ADDED: Create method for returning timestamp in nanoseconds

### v0.22.0 / 2025-02-25

- ADDED: Support 3.1 Min Version

### v0.21.0 / 2024-05-08

- ADDED: Untraced method updated to support both block and non block structured calls

### v0.20.1 / 2024-02-06

- FIXED: Patch the issue for frozen string on ruby < 3.0 with string interpolation

### v0.20.0 / 2023-06-08

- BREAKING CHANGE: Remove support for EoL Ruby 2.7

- ADDED: Remove support for EoL Ruby 2.7

### v0.19.7 / 2023-05-30

- FIXED: Untraced only works with parent-based sampler

### v0.19.6 / 2022-05-18

- (No significant changes)

### v0.19.5 / 2022-05-10

- FIXED: Common changelog

### v0.19.4 / 2022-05-08

- FIXED: Check that a variable is a string before truncating
- FIXED: Attribute length limit. only truncate strings and strings in arrays

### v0.19.3 / 2021-12-01

- FIXED: Change net attribute names to match the semantic conventions spec for http

### v0.19.2 / 2021-09-29

- (No significant changes)

### v0.19.1 / 2021-08-12

- (No significant changes)

### v0.19.0 / 2021-06-23

- ADDED: Add Tracer.non_recording_span to API

### v0.18.0 / 2021-05-21

- BREAKING CHANGE: Replace Time.now with Process.clock_gettime

- FIXED: Replace Time.now with Process.clock_gettime

### v0.17.0 / 2021-04-22

- ADDED: Add zipkin exporter
- ADDED: Processors validate exporters on init.

### v0.16.0 / 2021-03-17

- ADDED: Instrument lmdb gem
- FIXED: Remove passwords from http.url
- DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

- (No significant changes)

### v0.14.0 / 2021-02-03

- (No significant changes)

### v0.13.0 / 2021-01-29

- ADDED: Add untraced wrapper to common utils

### v0.12.0 / 2020-12-24

- (No significant changes)

### v0.11.0 / 2020-12-11

- ADDED: Move utf8 encoding to common utils
- FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

- FIXED: Common gem should depend on api gem

### v0.9.0 / 2020-11-27

- Initial release.
