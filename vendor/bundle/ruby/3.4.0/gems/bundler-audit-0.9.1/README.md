# bundler-audit

[![CI](https://github.com/rubysec/bundler-audit/actions/workflows/ruby.yml/badge.svg)](https://github.com/rubysec/bundler-audit/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/rubysec/bundler-audit.svg)](https://codeclimate.com/github/rubysec/bundler-audit)
[![Gem Version](https://badge.fury.io/rb/bundler-audit.svg)](https://badge.fury.io/rb/bundler-audit)

* [Homepage](https://github.com/rubysec/bundler-audit#readme)
* [Issues](https://github.com/rubysec/bundler-audit/issues)
* [Documentation](http://rubydoc.info/gems/bundler-audit/frames)

## Description

Patch-level verification for [bundler].

## Features

* Checks for vulnerable versions of gems in `Gemfile.lock`.
* Checks for insecure gem sources (`http://` and `git://`).
* Allows ignoring certain advisories that have been manually worked around.
* Prints advisory information.
* Does not require a network connection.

## Synopsis

Audit a project's `Gemfile.lock`:

    $ bundle-audit
    Name: actionpack
    Version: 3.2.10
    Advisory: OSVDB-91452
    Criticality: Medium
    URL: http://www.osvdb.org/show/osvdb/91452
    Title: XSS vulnerability in sanitize_css in Action Pack
    Solution: upgrade to ~> 2.3.18, ~> 3.1.12, >= 3.2.13

    Name: actionpack
    Version: 3.2.10
    Advisory: OSVDB-91454
    Criticality: Medium
    URL: http://osvdb.org/show/osvdb/91454
    Title: XSS Vulnerability in the `sanitize` helper of Ruby on Rails
    Solution: upgrade to ~> 2.3.18, ~> 3.1.12, >= 3.2.13

    Name: actionpack
    Version: 3.2.10
    Advisory: OSVDB-89026
    Criticality: High
    URL: http://osvdb.org/show/osvdb/89026
    Title: Ruby on Rails params_parser.rb Action Pack Type Casting Parameter Parsing Remote Code Execution
    Solution: upgrade to ~> 2.3.15, ~> 3.0.19, ~> 3.1.10, >= 3.2.11

    Name: activerecord
    Version: 3.2.10
    Advisory: OSVDB-91453
    Criticality: High
    URL: http://osvdb.org/show/osvdb/91453
    Title: Symbol DoS vulnerability in Active Record
    Solution: upgrade to ~> 2.3.18, ~> 3.1.12, >= 3.2.13

    Name: activerecord
    Version: 3.2.10
    Advisory: OSVDB-90072
    Criticality: Medium
    URL: http://direct.osvdb.org/show/osvdb/90072
    Title: Ruby on Rails Active Record attr_protected Method Bypass
    Solution: upgrade to ~> 2.3.17, ~> 3.1.11, >= 3.2.12

    Name: activerecord
    Version: 3.2.10
    Advisory: OSVDB-89025
    Criticality: High
    URL: http://osvdb.org/show/osvdb/89025
    Title: Ruby on Rails Active Record JSON Parameter Parsing Query Bypass
    Solution: upgrade to ~> 2.3.16, ~> 3.0.19, ~> 3.1.10, >= 3.2.11

    Name: activesupport
    Version: 3.2.10
    Advisory: OSVDB-91451
    Criticality: High
    URL: http://www.osvdb.org/show/osvdb/91451
    Title: XML Parsing Vulnerability affecting JRuby users
    Solution: upgrade to ~> 3.1.12, >= 3.2.13

    Unpatched versions found!

Update the [ruby-advisory-db] that `bundle audit` uses:

    $ bundle-audit update
    Updating ruby-advisory-db ...
    remote: Counting objects: 44, done.
    remote: Compressing objects: 100% (24/24), done.
    remote: Total 39 (delta 19), reused 29 (delta 10)
    Unpacking objects: 100% (39/39), done.
    From https://github.com/rubysec/ruby-advisory-db
     * branch            master     -> FETCH_HEAD
    Updating 5f8225e..328ca86
    Fast-forward
     CONTRIBUTORS.md                    |  1 +
     gems/actionmailer/OSVDB-98629.yml  | 17 +++++++++++++++++
     gems/cocaine/OSVDB-98835.yml       | 15 +++++++++++++++
     gems/fog-dragonfly/OSVDB-96798.yml | 13 +++++++++++++
     gems/sounder/OSVDB-96278.yml       | 13 +++++++++++++
     gems/wicked/OSVDB-98270.yml        | 14 ++++++++++++++
     6 files changed, 73 insertions(+)
     create mode 100644 gems/actionmailer/OSVDB-98629.yml
     create mode 100644 gems/cocaine/OSVDB-98835.yml
     create mode 100644 gems/fog-dragonfly/OSVDB-96798.yml
     create mode 100644 gems/sounder/OSVDB-96278.yml
     create mode 100644 gems/wicked/OSVDB-98270.yml
    ruby-advisory-db: 64 advisories

Update the [ruby-advisory-db] and check `Gemfile.lock` (useful for CI runs):

```shell
$ bundle-audit check --update
```

Checking the `Gemfile.lock` without updating the [ruby-advisory-db]:

```shell
$ bundle-audit check --no-update
```

Ignore specific advisories:

```shell
$ bundle-audit check --ignore OSVDB-108664
```

Checking a custom `Gemfile.lock` file:

```shell
$ bundle-audit check --gemfile-lock Gemfile.custom.lock
```

Output the audit's results in JSON:

```shell
$ bundle-audit check --format json
```

Output the audit's results in JSON, to a file:

```shell
$ bundle-audit check --format json --output bundle-audit.json
```

## Rake Tasks

Bundler-audit provides Rake tasks for checking the code and for updating
its vulnerability database:

```bash
rake bundle:audit
rake bundle:audit:update
```

## Configuration File

bundler-audit also supports a per-project configuration file:

`.bundler-audit.yml`:

```yaml
---
ignore:
  - CVE-YYYY-XXXX
  - ...
```

* `ignore:` \[Array\<String\>\] - A list of advisory IDs to ignore.

You can provide a path to a config file using the `--config` flag:

```shell
$ bundle-audit check --config bundler-audit.custom.yaml
```

## Requirements

* [git]
* [ruby] >= 2.0.0
* [rubygems] >= 1.8
* [thor] ~> 1.0
* [bundler] >= 1.2.0, < 3

## Install

```shell
$ [sudo] gem install bundler-audit
```

### Git

* Debian / Ubuntu:

```shell
$ sudo apt install git
```

* RedHat / Fedora:

```shell
$ sudo dnf install git
```

* Alpine Linux:

```shell
$ apk add git
```

* macOS:

```shell
$ brew install git
```

## Contributing

1. https://github.com/rubysec/bundler-audit/fork
2. `git clone YOUR_FORK_URI`
3. `cd bundler-audit/`
4. `bundle install`
5. `bundle exec rake spec`
6. `git checkout -b YOUR_FEATURE`
7. Make your changes
8. `bundle exec rake spec`
9. `git commit -a`
10. `git push origin YOUR_FEATURE`

## License

Copyright (c) 2013-2022 Hal Brodigan (postmodern.mod3 at gmail.com)

bundler-audit is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

bundler-audit is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with bundler-audit.  If not, see <https://www.gnu.org/licenses/>.

[git]: https://git-scm.com
[ruby]: https://ruby-lang.org
[rubygems]: https://rubygems.org
[thor]: http://whatisthor.com/
[bundler]: https://bundler.io

[OSVDB]: http://osvdb.org/
[ruby-advisory-db]: https://github.com/rubysec/ruby-advisory-db
