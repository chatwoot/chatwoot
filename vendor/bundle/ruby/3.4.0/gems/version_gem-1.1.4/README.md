# VersionGem

## Alternatives

This gem has a very niche purpose, which is:

1. providing introspection of a `Version` module based on a `Version::VERSION` constant string,
2. while not interfering with `gemspec` parsing where the `VERSION` string is traditionally used.

If this isn't **precisely** your use case you may be better off looking at
_[versionaire](https://www.alchemists.io/projects/versionaire)_, a wonderful, performant, well-maintained,
gem from the Alchemists, or _[version_sorter](https://rubygems.org/gems/version_sorter)_ from GitHub.

For more discussion about this [see issue #2](https://gitlab.com/oauth-xx/version_gem/-/issues/2)

-----

<div id="badges">

[![Liberapay Patrons][⛳liberapay-img]][⛳liberapay]
[![Sponsor Me on Github][🖇sponsor-img]][🖇sponsor]
<span class="badge-buymeacoffee">
<a href="https://ko-fi.com/O5O86SNP4" target='_blank' title="Donate to my FLOSS or refugee efforts at ko-fi.com"><img src="https://img.shields.io/badge/buy%20me%20coffee-donate-yellow.svg" alt="Buy me coffee donation button" /></a>
</span>
<span class="badge-patreon">
<a href="https://patreon.com/galtzo" title="Donate to my FLOSS or refugee efforts using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a>
</span>

</div>

[⛳liberapay-img]: https://img.shields.io/liberapay/patrons/pboling.svg?logo=liberapay
[⛳liberapay]: https://liberapay.com/pboling/donate
[🖇sponsor-img]: https://img.shields.io/badge/Sponsor_Me!-pboling.svg?style=social&logo=github
[🖇sponsor]: https://github.com/sponsors/pboling

## Still here?

Give your next library an introspectable `Version` module without breaking your Gemspec.

```ruby
MyLib::Version.to_s # => "1.2.3.rc3"
MyLib::Version.major # => 1
MyLib::Version.minor # => 2
MyLib::Version.patch # => 3
MyLib::Version.pre # => "rc3"
MyLib::Version.to_a # => [1, 2, 3, "rc3"]
MyLib::Version.to_h # => { major: 1, minor: 2, patch: 3, pre: "rc3" }
```

This library was extracted from the gem _[oauth2](https://gitlab.com/oauth-xx/oauth2)_.

This gem has no runtime dependencies.

<!--
Numbering rows and badges in each row as a visual "database" lookup,
    as the table is extremely dense, and it can be very difficult to find anything
Putting one on each row here, to document the emoji that should be used, and for ease of copy/paste.

row #s:
1️⃣
2️⃣
3️⃣
4️⃣
5️⃣
6️⃣
7️⃣

badge #s:
⛳️
🖇
🏘
🚎
🖐
🧮
📗

appended indicators:
♻️ - URL needs to be updated from SAAS integration. Find / Replace is insufficient.
-->

|     | Project                        | bundle add version_gem                                                                                                                                                                                                                                                     |
|:----|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1️⃣ | name, license, docs, standards | [![RubyGems.org][⛳️name-img]][⛳️gem] [![License: MIT][🖇src-license-img]][🖇src-license] [![RubyDoc.info][🚎yard-img]][🚎yard] [![SemVer 2.0.0][🧮semver-img]][🧮semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]                               |
| 2️⃣ | version & activity             | [![Gem Version][⛳️version-img]][⛳️gem] [![Total Downloads][🖇DL-total-img]][⛳️gem] [![Download Rank][🏘DL-rank-img]][⛳️gem] [![Source Code][🚎src-main-img]][🚎src-main] [![Open PRs][🖐prs-o-img]][🖐prs-o] [![Closed PRs][🧮prs-c-img]][🧮prs-c]                         |
| 3️⃣ | maintenance & linting          | [![Maintainability][⛳cclim-maint-img♻️]][⛳cclim-maint] [![Helpers][🖇triage-help-img]][🖇triage-help] [![Depfu][🏘depfu-img♻️]][🏘depfu♻️] [![Contributors][🚎contributors-img]][🚎contributors] [![Style][🖐style-wf-img]][🖐style-wf] [![Kloc Roll][🧮kloc-img]][🧮kloc] |
| 4️⃣ | testing                        | [![Supported][🏘sup-wf-img]][🏘sup-wf] [![Heads][🚎heads-wf-img]][🚎heads-wf] [![Unofficial Support][🖐uns-wf-img]][🖐uns-wf] <!--[![MacOS][🧮mac-wf-img]][🧮mac-wf] [![Windows][📗win-wf-img]][📗win-wf]-->                                                               |
| 5️⃣ | coverage & security            | [![CodeClimate][⛳cclim-cov-img♻️]][⛳cclim-cov] [![CodeCov][🖇codecov-img♻️]][🖇codecov] [![Coveralls][🏘coveralls-img]][🏘coveralls] [![Security Policy][🚎sec-pol-img]][🚎sec-pol] [![CodeQL][🖐codeQL-img]][🖐codeQL] [![Code Coverage][🧮cov-wf-img]][🧮cov-wf]         |
| 6️⃣ | resources                      | [![Get help on Codementor][🖇codementor-img]][🖇codementor] [![Chat][🏘chat-img]][🏘chat] [![Blog][🚎blog-img]][🚎blog] [![Wiki][🖐wiki-img]][🖐wiki]                                                                                                                      |
| 7️⃣ | spread 💖                      | [![Liberapay Patrons][⛳liberapay-img]][⛳liberapay] [![Sponsor Me][🖇sponsor-img]][🖇sponsor] [![Tweet @ Peter][🏘tweet-img]][🏘tweet] [🌏][aboutme] [👼][angelme] [💻][coderme]                                                                                            |

<!--
The link tokens in the following sections should be kept ordered by the row and badge numbering scheme
-->

<!-- 1️⃣ name, license, docs -->
[⛳️gem]: https://rubygems.org/gems/version_gem
[⛳️name-img]: https://img.shields.io/badge/name-version_gem-brightgreen.svg?style=flat
[🖇src-license]: https://opensource.org/licenses/MIT
[🖇src-license-img]: https://img.shields.io/badge/License-MIT-green.svg
[🚎yard]: https://www.rubydoc.info/gems/version_gem
[🚎yard-img]: https://img.shields.io/badge/documentation-rubydoc-brightgreen.svg?style=flat
[🧮semver]: http://semver.org/
[🧮semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

<!-- 2️⃣ version & activity -->
[⛳️version-img]: http://img.shields.io/gem/v/version_gem.svg
[🖇DL-total-img]: https://img.shields.io/gem/dt/version_gem.svg
[🏘DL-rank-img]: https://img.shields.io/gem/rt/version_gem.svg
[🚎src-main]: https://gitlab.com/oauth-xx/version_gem
[🚎src-main-img]: https://img.shields.io/badge/source-gitlab-brightgreen.svg?style=flat
[🖐prs-o]: https://gitlab.com/oauth-xx/version_gem/-/merge_requests
[🖐prs-o-img]: https://img.shields.io/github/issues-pr/pboling/version_gem
[🧮prs-c]: https://github.com/pboling/version_gem/pulls?q=is%3Apr+is%3Aclosed
[🧮prs-c-img]: https://img.shields.io/github/issues-pr-closed/pboling/version_gem

<!-- 3️⃣ maintenance & linting -->
[⛳cclim-maint]: https://codeclimate.com/github/pboling/version_gem/maintainability
[⛳cclim-maint-img♻️]: https://api.codeclimate.com/v1/badges/b504d61c4ed1d46aec02/maintainability
[🖇triage-help]: https://www.codetriage.com/pboling/version_gem
[🖇triage-help-img]: https://www.codetriage.com/pboling/version_gem/badges/users.svg
[🏘depfu♻️]: https://depfu.com/github/pboling/version_gem?project_id=35803
[🏘depfu-img♻️]: https://badges.depfu.com/badges/5d8943de6cfdf1ee048ad6d907f3e35b/count.svg
[🚎contributors]: https://gitlab.com/oauth-xx/version_gem/-/graphs/main
[🚎contributors-img]: https://img.shields.io/github/contributors-anon/pboling/version_gem
[🖐style-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/style.yml
[🖐style-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/style.yml/badge.svg
[🧮kloc]: https://www.youtube.com/watch?v=dQw4w9WgXcQ
[🧮kloc-img]: https://img.shields.io/tokei/lines/github.com/pboling/version_gem

<!-- 4️⃣ testing -->
[🏘sup-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/supported.yml
[🏘sup-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/supported.yml/badge.svg
[🚎heads-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/heads.yml
[🚎heads-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/heads.yml/badge.svg
[🖐uns-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/unsupported.yml
[🖐uns-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/unsupported.yml/badge.svg
[🧮mac-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/macos.yml
[🧮mac-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/macos.yml/badge.svg
[📗win-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/windows.yml
[📗win-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/windows.yml/badge.svg

<!-- 5️⃣ coverage & security -->
[⛳cclim-cov]: https://codeclimate.com/github/pboling/version_gem/test_coverage
[⛳cclim-cov-img♻️]: https://api.codeclimate.com/v1/badges/b504d61c4ed1d46aec02/test_coverage
[🖇codecov-img♻️]: https://codecov.io/gh/pboling/version_gem/branch/main/graph/badge.svg?token=79c3X4vtfO
[🖇codecov]: https://codecov.io/gh/pboling/version_gem
[🏘coveralls]: https://coveralls.io/github/pboling/version_gem?branch=main
[🏘coveralls-img]: https://coveralls.io/repos/github/pboling/version_gem/badge.svg?branch=main
[🚎sec-pol]: https://gitlab.com/oauth-xx/version_gem/-/blob/main/SECURITY.md
[🚎sec-pol-img]: https://img.shields.io/badge/security-policy-brightgreen.svg?style=flat
[🖐codeQL]: https://github.com/pboling/version_gem/security/code-scanning
[🖐codeQL-img]: https://github.com/oauth-xx/version_gem/actions/workflows/codeql-analysis.yml/badge.svg
[🧮cov-wf]: https://github.com/oauth-xx/version_gem/actions/workflows/coverage.yml
[🧮cov-wf-img]: https://github.com/oauth-xx/version_gem/actions/workflows/coverage.yml/badge.svg

<!-- 6️⃣ resources -->
[🖇codementor]: https://www.codementor.io/peterboling?utm_source=github&utm_medium=button&utm_term=peterboling&utm_campaign=github
[🖇codementor-img]: https://cdn.codementor.io/badges/get_help_github.svg
[🏘chat]: https://gitter.im/oauth-xx/version_gem
[🏘chat-img]: https://img.shields.io/gitter/room/oauth-xx/version_gem.svg
[🚎blog]: http://www.railsbling.com/tags/version_gem/
[🚎blog-img]: https://img.shields.io/badge/blog-railsbling-brightgreen.svg?style=flat
[🖐wiki]: https://gitlab.com/oauth-xx/version_gem/-/wikis/home
[🖐wiki-img]: https://img.shields.io/badge/wiki-examples-brightgreen.svg?style=flat

<!-- 7️⃣ spread 💖 -->
[⛳liberapay-img]: https://img.shields.io/liberapay/patrons/pboling.svg?logo=liberapay
[⛳liberapay]: https://liberapay.com/pboling/donate
[🖇sponsor-img]: https://img.shields.io/badge/sponsor-pboling.svg?style=social&logo=github
[🖇sponsor]: https://github.com/sponsors/pboling
[🏘tweet-img]: https://img.shields.io/twitter/follow/galtzo.svg?style=social&label=Follow
[🏘tweet]: http://twitter.com/galtzo

<!-- Maintainer Contact Links -->
[railsbling]: http://www.railsbling.com
[peterboling]: http://www.peterboling.com
[aboutme]: https://about.me/peter.boling
[angelme]: https://angel.co/peter-boling
[coderme]:http://coderwall.com/pboling

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add version_gem

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install version_gem

## Usage

In the standard `bundle gem my_lib` code you get the following in `lib/my_lib/version.rb`:

```ruby
module MyLib
  VERSION = "0.1.0"
end
```

Change it to a nested `Version` namespace (the one implied by the path => namespace convention):

```ruby
module MyLib
  module Version
    VERSION = "0.1.0"
  end
end
```

Now add the following near the top of the file the manages requiring external libraries.
Using the same example of `bundle gem my_lib`, this would be `lib/my_lib.rb`.

```ruby
require "version_gem"
```

Then, add the following wherever you want in the same file (recommend the bottom).

```ruby
MyLib::Version.class_eval do
  extend VersionGem::Basic
end
```

And now you have some version introspection methods available:

```ruby
MyLib::Version.to_s # => "0.1.0"
MyLib::Version.major # => 0
MyLib::Version.minor # => 1
MyLib::Version.patch # => 0
MyLib::Version.pre # => ""
MyLib::Version.to_a # => [0, 1, 0]
MyLib::Version.to_h # => { major: 0, minor: 1, patch: 0, pre: "" }
```

### Side benefit

Your `version.rb` file now abides the Ruby convention of directory / path matching the namespace / class!

### Zietwerk

The pattern of `version.rb` breaking the ruby convention of directory / path matching the namespace / class
is so entrenched that the `zeitwerk` library has a special carve-out for it.
RubyGems using this "bad is actually good" pattern are encouraged to use `Zeitwerk.for_gem`.

**Do not do that ^** if you use this gem.

#### Simple Zeitwerk Example

Create a gem like this (keeping with the `MyLib` theme):

```shell
bundle gem my_lib
```

Then following the usage instructions above, you edit your primary namespace file @ `lib/my_lib.rb`,
but inject the Zeitwerk loader.

```ruby
# frozen_string_literal: true

require_relative "my_lib/version"

module MyLib
  class Error < StandardError; end
  # Your code goes here...
end

loader = Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, ".rb")
loader.push_dir("lib/my_lib", namespace: MyLib)
loader.setup # ready!
loader.eager_load(force: true) # optional!

MyLib::Version.class_eval do
  extend VersionGem::Basic
end
```

#### Complex Zeitwerk Example


#### Query Ruby Version (as of version 1.2.0)

In Continuous Integration environments for libraries that run against many versions of Ruby,
I often need to configure things discretely per Ruby version, and doing so forced me to repeat
a significant amount of boilerplate code across each project.

Thus `VersionGem::Ruby` was born.  It has the two optimized methods I always need:

```ruby
engine = "ruby"
version = "2.7.7"
gte_minimum_version?(version, engine)  # Is the current version of Ruby greater than or equal to some minimum?

major = 3
minor = 2
actual_minor_version?(major, minor, engine) # Is the current version of Ruby precisely a specific minor version of Ruby?
```

`Version::Ruby` is *not loaded* by default.  If you want to use it, you must require it as:
```ruby
require "version_gem/ruby"
```

Normally I do this in my `spec/spec_helper.rb`, and/or `.simplecov` files.
Occasionally in my `Rakefile`.

### Caveat

This design keeps your `version.rb` file compatible with the way `gemspec` files use them.
This means that the introspection is _not_ available within the gemspec.
The enhancement from this gem is only available at runtime.

### RSpec Matchers

In `spec_helper.rb`:
```ruby
require "version_gem/rspec"
```

Then you can write a test like:

```ruby
RSpec.describe(MyLib::Version) do
  it_behaves_like "a Version module", described_class
end

# Or, if you want to write your own, here is the a la carte menu:
RSpec.describe(MyLib::Version) do
  it "is a Version module" do
    expect(described_class).is_a?(Module)
    expect(described_class).to(have_version_constant)
    expect(described_class).to(have_version_as_string)
    expect(described_class.to_s).to(be_a(String))
    expect(described_class).to(have_major_as_integer)
    expect(described_class).to(have_minor_as_integer)
    expect(described_class).to(have_patch_as_integer)
    expect(described_class).to(have_pre_as_nil_or_string)
    expect(described_class.to_h.keys).to(match_array(%i[major minor patch pre]))
    expect(described_class.to_a).to(be_a(Array))
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

See [CONTRIBUTING.md][contributing]

## Contributors

[![Contributors](https://contrib.rocks/image?repo=pboling/version_gem)]("https://gitlab.com/oauth-xx/version_gem/-/graphs/main")

Made with [contributors-img](https://contrib.rocks).

## License

The gem is available as open source under the terms of
the [MIT License][license] [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)][license-ref].
See [LICENSE][license] for the official [Copyright Notice][copyright-notice-explainer].

* Copyright (c) 2022 - 2023 [Peter H. Boling][peterboling] of [Rails Bling][railsbling]

## Code of Conduct

Everyone interacting in the VersionGem project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://gitlab.com/oauth-xx/version_gem/-/blob/main/CODE_OF_CONDUCT.md).

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][🧮semver]. Violations of this scheme should be reported as
bugs. Specifically, if a minor or patch version is released that breaks backward compatibility, a new version should be
immediately released that restores compatibility. Breaking changes to the public API will only be introduced with new
major versions.

As a result of this policy, you can (and should) specify a dependency on this gem using
the [Pessimistic Version Constraint][pvc] with two digits of precision.

For example:

```ruby
spec.add_dependency("version_gem", "~> 1.1")
```

## Security

See [SECURITY.md](https://gitlab.com/oauth-xx/version_gem/-/blob/main/SECURITY.md).

[aboutme]: https://about.me/peter.boling
[actions]: https://github.com/oauth-xx/version_gem/actions
[angelme]: https://angel.co/peter-boling
[blogpage]: http://www.railsbling.com/tags/version_gem/
[codecov_coverage]: https://codecov.io/gh/oauth-xx/version_gem
[code_triage]: https://www.codetriage.com/oauth-xx/version_gem
[chat]: https://gitter.im/oauth-xx/version_gem?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[climate_coverage]: https://codeclimate.com/github/oauth-xx/version_gem/test_coverage
[climate_maintainability]: https://codeclimate.com/github/oauth-xx/version_gem/maintainability
[copyright-notice-explainer]: https://opensource.stackexchange.com/questions/5778/why-do-licenses-such-as-the-mit-license-specify-a-single-year
[conduct]: https://gitlab.com/oauth-xx/version_gem/-/blob/main/CODE_OF_CONDUCT.md
[contributing]: https://gitlab.com/oauth-xx/version_gem/-/blob/main/CONTRIBUTING.md
[devto]: https://dev.to/galtzo
[documentation]: https://rubydoc.info/github/oauth-xx/version_gem/main
[followme]: https://img.shields.io/twitter/follow/galtzo.svg?style=social&label=Follow
[gh_sponsors]: https://github.com/sponsors/pboling
[issues]: https://github.com/oauth-xx/version_gem/issues
[liberapay_donate]: https://liberapay.com/pboling/donate
[license]: LICENSE.txt
[license-ref]: https://opensource.org/licenses/MIT
[license-img]: https://img.shields.io/badge/License-MIT-green.svg
[peterboling]: http://www.peterboling.com
[pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint
[railsbling]: http://www.railsbling.com
[rubygems]: https://rubygems.org/gems/version_gem
[security]: https://gitlab.com/oauth-xx/version_gem/-/blob/main/SECURITY.md
[semver]: http://semver.org/
[source]: https://gitlab.com/oauth-xx/version_gem
[tweetme]: http://twitter.com/galtzo
