## [Unreleased]

## [1.1.0]

- Add `LintRoller::Support` module of classes designed to make it a little
easier to author plugins. `MergesUpstreamMetadata#merge` will allow a minimal
YAML config (say, `standard-sorbet`'s, which only contains `Enabled` values for
each rule) to merge in any other defaults from a source YAML (e.g.
`rubocop-sorbet`'s which includes `Description`, `VersionAdded`, and so on).
This way that metadata is neither absent at runtime nor duplicated in a standard
plugin that mirrors a rubocop extension

## [1.0.0]

- Initial release
