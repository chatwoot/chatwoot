# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.2.0 / 2022-07-15

- Added: `ClimateControl.unsafe_modify` for a thread-unsafe version of
  `ClimateControl.modify` (useful for minitest-around for instance)
- Deprecates `ClimateControl.env`, `ENV` should be used instead

## 1.1.1 / 2022-05-28

- Fixed: ENV was not restored if an error was thrown when assigning ENV

## 1.1.0 / 2022-05-26

- Refactor to use `Monitor` instead of `Mutex`
- Add documentation about thread-safety
- Allow ClimateControl.modify to be called without environment variables
- Add test for concurrent access needed to be inside block
- Relax development dependencies

## 1.0.1 / 2021-05-26

- Require minimum Ruby version of 2.5.0

# 1.0.0 / 2021-03-06

- Commit to supporting latest patch versions of Ruby 2.5+
- Improve documentation
- Format code with StandardRB
- Bump gem dependencies

# 0.2.0 / 2017-05-12

- Allow nested environment changes in the same thread

# 0.1.0 / 2017-01-07

- Remove ActiveSupport dependency

# 0.0.4 / 2017-01-06

- Improved thread safety
- Handle TypeErrors during assignment
- Improve documentation

# 0.0.1 / 2012-11-28

- Initial release
