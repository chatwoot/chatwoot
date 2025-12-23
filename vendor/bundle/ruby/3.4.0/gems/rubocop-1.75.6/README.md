<p align="center">
  <img src="https://raw.githubusercontent.com/rubocop/rubocop/master/logo/rubo-logo-horizontal-white.png" alt="RuboCop Logo"/>
</p>

----------
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![Gem Version](https://badge.fury.io/rb/rubocop.svg)](https://badge.fury.io/rb/rubocop)
[![CI](https://github.com/rubocop/rubocop/actions/workflows/rubocop.yml/badge.svg)](https://github.com/rubocop/rubocop/actions/workflows/rubocop.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/d2d67f728e88ea84ac69/test_coverage)](https://codeclimate.com/github/rubocop/rubocop/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/d2d67f728e88ea84ac69/maintainability)](https://codeclimate.com/github/rubocop/rubocop/maintainability)
[![Discord](https://img.shields.io/badge/chat-on%20discord-7289da.svg?sanitize=true)](https://discord.gg/wJjWvGRDmm)

> Role models are important. <br/>
> -- Officer Alex J. Murphy / RoboCop

**RuboCop** is a Ruby static code analyzer (a.k.a. `linter`) and code formatter. Out of the box it
will enforce many of the guidelines outlined in the community [Ruby Style
Guide](https://rubystyle.guide). Apart from reporting the problems discovered in your code,
RuboCop can also automatically fix many of them for you.

RuboCop is extremely flexible and most aspects of its behavior can be tweaked via various
[configuration options](https://github.com/rubocop/rubocop/blob/master/config/default.yml).

----------
[![Patreon](https://img.shields.io/badge/patreon-donate-orange.svg)](https://www.patreon.com/bbatsov)
[![OpenCollective](https://opencollective.com/rubocop/backers/badge.svg)](#open-collective-for-individuals)
[![OpenCollective](https://opencollective.com/rubocop/sponsors/badge.svg)](#open-collective-for-organizations)
[![Tidelift](https://tidelift.com/badges/package/rubygems/rubocop)](https://tidelift.com/subscription/pkg/rubygems-rubocop?utm_source=rubygems-rubocop&utm_medium=referral&utm_campaign=readme)

Working on RuboCop is often fun, but it also requires a great deal of time and energy.

**Please consider [financially supporting its ongoing development](#funding).**

## Installation

**RuboCop**'s installation is pretty standard:

```sh
$ gem install rubocop
```

If you'd rather install RuboCop using `bundler`, add a line for it in your `Gemfile` (but set the `require` option to `false`, as it is a standalone tool):

```rb
gem 'rubocop', require: false
```

RuboCop is stable between minor versions, both in terms of API and cop configuration.
We aim to ease the maintenance of RuboCop extensions and the upgrades between RuboCop
releases. All big changes are reserved for major releases.
To prevent an unwanted RuboCop update you might want to use a conservative version lock
in your `Gemfile`:

```rb
gem 'rubocop', '~> 1.75', require: false
```

See [our versioning policy](https://docs.rubocop.org/rubocop/versioning.html) for further details.

## Quickstart

Just type `rubocop` in a Ruby project's folder and watch the magic happen.

```
$ cd my/cool/ruby/project
$ rubocop
```

You can also use this magic in your favorite editor with RuboCop's [built-in LSP server](https://docs.rubocop.org/rubocop/usage/lsp.html).

## Documentation

You can read a lot more about RuboCop in its [official docs](https://docs.rubocop.org).

## Compatibility

RuboCop officially supports the following runtime Ruby implementations:

* MRI 2.7+
* JRuby 9.4+

Targets Ruby 2.0+ code analysis.

See the [compatibility documentation](https://docs.rubocop.org/rubocop/compatibility.html) for further details.

## Readme Badge

If you use RuboCop in your project, you can include one of these badges in your readme to let people know that your code is written following the community Ruby Style Guide.

[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

[![Ruby Style Guide](https://img.shields.io/badge/code_style-community-brightgreen.svg)](https://rubystyle.guide)


Here are the Markdown snippets for the two badges:

``` markdown
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

[![Ruby Style Guide](https://img.shields.io/badge/code_style-community-brightgreen.svg)](https://rubystyle.guide)
```

## Team

Here's a list of RuboCop's core developers:

* [Bozhidar Batsov](https://github.com/bbatsov) (author & head maintainer)
* [Jonas Arvidsson](https://github.com/jonas054)
* [Yuji Nakayama](https://github.com/yujinakayama) (retired)
* [Evgeni Dzhelyov](https://github.com/edzhelyov) (retired)
* [Ted Johansson](https://github.com/drenmi)
* [Masataka Kuwabara](https://github.com/pocke)
* [Koichi Ito](https://github.com/koic)
* [Maxim Krizhanovski](https://github.com/darhazer)
* [Benjamin Quorning](https://github.com/bquorning)
* [Marc-André Lafortune](https://github.com/marcandre)
* [Daniel Vandersluis](https://github.com/dvandersluis)

See the [team page](https://docs.rubocop.org/rubocop/about/team.html) for more details.

## Logo

RuboCop's logo was created by [Dimiter Petrov](https://www.chadomoto.com/). You can find the logo in various
formats [here](https://github.com/rubocop/rubocop/tree/master/logo).

The logo is licensed under a
[Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/deed.en_GB).

## Contributors

Here's a [list](https://github.com/rubocop/rubocop/graphs/contributors) of
all the people who have contributed to the development of RuboCop.

I'm extremely grateful to each and every one of them!

If you'd like to contribute to RuboCop, please take the time to go
through our short
[contribution guidelines](CONTRIBUTING.md).

Converting more of the Ruby Style Guide into RuboCop cops is our top
priority right now. Writing a new cop is a great way to dive into RuboCop!

Of course, bug reports and suggestions for improvements are always
welcome. GitHub pull requests are even better! :-)

## Funding

While RuboCop is free software and will always be, the project would benefit immensely from some funding.
Raising a monthly budget of a couple of thousand dollars would make it possible to pay people to work on
certain complex features, fund other development related stuff (e.g. hardware, conference trips) and so on.
Raising a monthly budget of over $5000 would open the possibility of someone working full-time on the project
which would speed up the pace of development significantly.

We welcome both individual and corporate sponsors! We also offer a
wide array of funding channels to account for your preferences
(although
currently [Open Collective](https://opencollective.com/rubocop) is our
preferred funding platform).

**If you're working in a company that's making significant use of RuboCop we'd appreciate it if you suggest to your company
to become a RuboCop sponsor.**

You can support the development of RuboCop via
[GitHub Sponsors](https://github.com/sponsors/bbatsov),
[Patreon](https://www.patreon.com/bbatsov),
[PayPal](https://paypal.me/bbatsov),
[Open Collective](https://opencollective.com/rubocop)
and [Tidelift](https://tidelift.com/subscription/pkg/rubygems-rubocop?utm_source=rubygems-rubocop&utm_medium=referral&utm_campaign=readme)
.

**Note:** If doing a sponsorship in the form of donation is problematic for your company from an accounting standpoint, we'd recommend
the use of Tidelift, where you can get a support-like subscription instead.

### Open Collective for Individuals

Support us with a monthly donation and help us continue our activities. [[Become a backer](https://opencollective.com/rubocop#backer)]

<a href="https://opencollective.com/rubocop/individual/0/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/0/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/1/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/1/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/2/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/2/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/3/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/3/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/4/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/4/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/5/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/5/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/6/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/6/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/7/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/7/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/8/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/8/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/9/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/9/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/10/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/10/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/11/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/11/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/12/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/12/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/13/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/13/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/14/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/14/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/15/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/15/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/16/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/16/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/17/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/17/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/18/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/18/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/19/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/19/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/20/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/20/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/21/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/21/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/22/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/22/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/23/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/23/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/24/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/24/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/25/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/25/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/26/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/26/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/27/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/27/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/28/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/28/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/individual/29/website" target="_blank"><img src="https://opencollective.com/rubocop/individual/29/avatar.svg"></a>

### Open Collective for Organizations

Become a sponsor and get your logo on our README on GitHub with a link to your site. [[Become a sponsor](https://opencollective.com/rubocop#sponsor)]

<a href="https://opencollective.com/rubocop/organization/0/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/0/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/1/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/1/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/2/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/2/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/3/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/3/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/4/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/4/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/5/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/5/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/6/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/6/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/7/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/7/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/8/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/8/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/9/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/9/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/10/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/10/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/11/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/11/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/12/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/12/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/13/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/13/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/14/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/14/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/15/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/15/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/16/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/16/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/17/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/17/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/18/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/18/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/19/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/19/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/20/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/20/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/21/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/21/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/22/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/22/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/23/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/23/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/24/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/24/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/25/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/25/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/26/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/26/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/27/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/27/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/28/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/28/avatar.svg"></a>
<a href="https://opencollective.com/rubocop/organization/29/website" target="_blank"><img src="https://opencollective.com/rubocop/organization/29/avatar.svg"></a>

## Release Notes

RuboCop's release notes are available [here](https://github.com/rubocop/rubocop/releases).

## Copyright

Copyright (c) 2012-2025 Bozhidar Batsov. See [LICENSE.txt](LICENSE.txt) for
further details.
