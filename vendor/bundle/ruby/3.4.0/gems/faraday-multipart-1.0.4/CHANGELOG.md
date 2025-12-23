# Changelog

## [1.0.4](https://github.com/lostisland/faraday-multipart/releases/tag/v1.0.3) (2022-06-07)

### What's Changed

* Drop support for 'multipart-post' < 2.0.0. This is not a breaking change as this gem's code didn't work with 1.x.
* Change references to `UploadIO` and `Parts` according to class reorganization in the 'multipart-post' gem 2.2.0 (see [multipart-post gem PR #89](https://github.com/socketry/multipart-post/pull/89))
* Introduce a backwards compatible safeguard so the gem still works with previous 'multipart-post' 2.x releases.

## [1.0.3](https://github.com/lostisland/faraday-multipart/releases/tag/v1.0.3) (2022-01-08)

### What's Changed

* Add `Faraday::ParamPart` alias back by @iMacTia in https://github.com/lostisland/faraday-multipart/pull/2

**Full Changelog**: https://github.com/lostisland/faraday-multipart/compare/v1.0.2...v1.0.3

## [1.0.2](https://github.com/lostisland/faraday-multipart/releases/tag/v1.0.2) (2022-01-06)

### Fixes

* Add missing UploadIO alias
* Re-add support for Ruby 2.4+

**Full Changelog**: https://github.com/lostisland/faraday-multipart/compare/v1.0.1...v1.0.2

## [1.0.1](https://github.com/lostisland/faraday-multipart/releases/tag/v1.0.1) (2022-01-06)

### What's Changed
* Add support for Faraday v1 by @iMacTia in https://github.com/lostisland/faraday-multipart/pull/1

**Full Changelog**: https://github.com/lostisland/faraday-multipart/compare/v1.0.0...v1.0.1

## [1.0.0](https://github.com/lostisland/faraday-multipart/releases/tag/v1.0.0) (2022-01-04)

### Summary

The initial release of the `faraday-multipart` gem.

This middleware was previously bundled with Faraday but was removed as of v2.0.

### MIGRATION NOTES

If you're upgrading from Faraday 1.0 and including this middleware as a gem, please be aware the namespacing for helper classes has changed:

* `Faraday::FilePart` is now `Faraday::Multipart::FilePart`
* `Faraday::Parts` is now `Faraday::Multipart::Parts`
* `Faraday::CompositeReadIO` is now `Faraday::Multipart::CompositeReadIO`
* `Faraday::ParamPart` is now `Faraday::Multipart::ParamPart`

Moreover, in case you're adding the middleware to your faraday connection with the full qualified name rather than the `:multipart` alias, please be aware the middleware class is now `Faraday::Multipart::Middleware`.
