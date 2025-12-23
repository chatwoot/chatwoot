# Changelog

## Unreleased

* Avoid deprecation warning about ::UploadIO constant when used without faraday-multipart gem [PR #37](https://github.com/lostisland/faraday-retry/pull/37) [@iMacTia]
* Documentation update [PR #30](https://github.com/lostisland/faraday-retry/pull/30) [@olleolleolle]
* Documentation update [PR #32](https://github.com/lostisland/faraday-retry/pull/32) Thanks, [@Drowze]!

## v2.2.0 (2023-06-01)

* Support new `header_parser_block` option. [PR #28](https://github.com/lostisland/faraday-retry/pull/28). Thanks, [@zavan]!

## v2.1.0 (2023-03-03)

* Support for custom RateLimit headers. [PR #13](https://github.com/lostisland/faraday-retry/pull/13). Thanks, [@brookemckim]!

v2.1.1 (2023-02-17) is a spurious not-released version that you may have seen mentioned in this CHANGELOG.

## v2.0.0 (2022-06-08)

### Changed

* `retry_block` now takes keyword arguments instead of positional (backwards incompatible)
* `retry_block`'s `retry_count` argument now counts up from 0, instead of old `retries_remaining`

### Added

* Support for the `RateLimit-Reset` header. [PR #9](https://github.com/lostisland/faraday-retry/pull/9). Thanks, [@maxprokopiev]!
* `retry_block` has additional `will_retry_in` argument with upcoming delay before retry in seconds.

## v1.0

Initial release.
This release consists of the same middleware that was previously bundled with Faraday but removed in Faraday v2.0, plus:

### Fixed

*  Retry middleware `retry_block` is not called if retry will not happen due to `max_interval`, https://github.com/lostisland/faraday/pull/1350

[@maxprokopiev]: https://github.com/maxprokopiev
[@brookemckim]: https://github.com/brookemckim
[@zavan]: https://github.com/zavan
[@Drowze]: https://github.com/Drowze
[@olleolleolle]: https://github.com/olleolleolle
[@iMacTia]: https://github.com/iMacTia
