# Versioning Strategy

`twilio-ruby` uses a modified version of [Semantic Versioning][semver] for
all changes to the helper library. It is strongly encouraged that you pin at
least the major version and potentially the minor version to avoid pulling in
breaking changes.

Semantic Versions take the form of `MAJOR.MINOR.PATCH`

When bugs are fixed in the library in a backwards-compatible way, the `PATCH`
level will be incremented by one. When new features are added to the library
in a backwards-compatible way, the `PATCH` level will be incremented by one.
`PATCH` changes should _not_ break your code and are generally safe for upgrade.

When a new large feature set comes online or a small breaking change is
introduced, the `MINOR` version will be incremented by one and the `PATCH`
version reset to zero. `MINOR` changes _may_ require some amount of manual code
change for upgrade. These backwards-incompatible changes will generally be
limited to a small number of function signature changes.

The `MAJOR` version is used to indicate the family of technology represented by
the helper library. Breaking changes that require extensive reworking of code
will cause the `MAJOR` version to be incremented by one, and the `MINOR` and
`PATCH` versions will be reset to zero. Twilio understands that this can be very
disruptive, so we will only introduce this type of breaking change when
absolutely necessary. New `MAJOR` versions will be communicated in advance with
`Release Candidates` and a schedule.

## Supported Versions

Only the current `MAJOR` version of `twilio-ruby` is supported. New
features, functionality, bug fixes, and security updates will only be added to
the current `MAJOR` version.

[semver]: https://semver.org