[![Brakeman Logo](http://brakemanscanner.org/images/logo_medium.png)](http://brakemanscanner.org/)

[![Build Status](https://circleci.com/gh/presidentbeef/brakeman.svg?style=svg)](https://circleci.com/gh/presidentbeef/brakeman)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1b08a5c74695cb0d11ec/test_coverage)](https://codeclimate.com/github/presidentbeef/brakeman/test_coverage)
[![Gitter](https://badges.gitter.im/presidentbeef/brakeman.svg)](https://gitter.im/presidentbeef/brakeman)

# Brakeman

Brakeman is a static analysis tool which checks Ruby on Rails applications for security vulnerabilities.

# Installation

Using RubyGems:

    gem install brakeman

Using Bundler:

```ruby
group :development do
  gem 'brakeman'
end
```

Using Docker:

    docker pull presidentbeef/brakeman

Using Docker to build from source:

    git clone https://github.com/presidentbeef/brakeman.git
    cd brakeman
    docker build . -t brakeman

# Usage

#### Running locally

From a Rails application's root directory:

    brakeman

Outside of Rails root:

    brakeman /path/to/rails/application

#### Running with Docker

From a Rails application's root directory:

    docker run -v "$(pwd)":/code presidentbeef/brakeman

With a little nicer color:

    docker run -v "$(pwd)":/code presidentbeef/brakeman --color

For an HTML report:

    docker run -v "$(pwd)":/code presidentbeef/brakeman -o brakeman_results.html

Outside of Rails root (note that the output file is relative to path/to/rails/application):

    docker run -v 'path/to/rails/application':/code presidentbeef/brakeman -o brakeman_results.html

# Compatibility

Brakeman should work with any version of Rails from 2.3.x to 7.x.

Brakeman can analyze code written with Ruby 1.8 syntax and newer, but requires at least Ruby 2.5.0 to run.

# Basic Options

For a full list of options, use `brakeman --help` or see the [OPTIONS.md](OPTIONS.md) file.

To specify an output file for the results:

    brakeman -o output_file

The output format is determined by the file extension or by using the `-f` option. Current options are: `text`, `html`, `tabs`, `json`, `junit`, `markdown`, `csv`, `codeclimate`, and `sonar`.

Multiple output files can be specified:

    brakeman -o output.html -o output.json

To output to both a file and to the console, with color:

    brakeman --color -o /dev/stdout -o output.json

To suppress informational warnings and just output the report:

    brakeman -q

Note all Brakeman output except reports are sent to stderr, making it simple to redirect stdout to a file and just get the report.

To see all kinds of debugging information:

    brakeman -d

Specific checks can be skipped, if desired. The name needs to be the correct case. For example, to skip looking for default routes (`DefaultRoutes`):

    brakeman -x DefaultRoutes

Multiple checks should be separated by a comma:

    brakeman -x DefaultRoutes,Redirect

To do the opposite and only run a certain set of tests:

    brakeman -t SQL,ValidationRegex

If Brakeman is running a bit slow, try

    brakeman --faster

This will disable some features, but will probably be much faster (currently it is the same as `--skip-libs --no-branching`). *WARNING*: This may cause Brakeman to miss some vulnerabilities.

By default, Brakeman will return a non-zero exit code if any security warnings are found or scanning errors are encountered. To disable this:

    brakeman --no-exit-on-warn --no-exit-on-error

To skip certain files or directories that Brakeman may have trouble parsing, use:

    brakeman --skip-files file1,/path1/,path2/

To compare results of a scan with a previous scan, use the JSON output option and then:

    brakeman --compare old_report.json

This will output JSON with two lists: one of fixed warnings and one of new warnings.

Brakeman will ignore warnings if configured to do so. By default, it looks for a configuration file in `config/brakeman.ignore`.
To create and manage this file, use:

    brakeman -I

# Warning information

See [warning\_types](docs/warning_types) for more information on the warnings reported by this tool.

# Warning context

The HTML output format provides an excerpt from the original application source where a warning was triggered. Due to the processing done while looking for vulnerabilities, the source may not resemble the reported warning and reported line numbers may be slightly off. However, the context still provides a quick look into the code which raised the warning.

# Confidence levels

Brakeman assigns a confidence level to each warning. This provides a rough estimate of how certain the tool is that a given warning is actually a problem. Naturally, these ratings should not be taken as absolute truth.

There are three levels of confidence:

 + High - Either this is a simple warning (boolean value) or user input is very likely being used in unsafe ways.
 + Medium - This generally indicates an unsafe use of a variable, but the variable may or may not be user input.
 + Weak - Typically means user input was indirectly used in a potentially unsafe manner.

To only get warnings above a given confidence level:

    brakeman -w3

The `-w` switch takes a number from 1 to 3, with 1 being low (all warnings) and 3 being high (only highest confidence warnings).

# Configuration files

Brakeman options can be stored and read from YAML files.

To simplify the process of writing a configuration file, the `-C` option will output the currently set options:

```sh
$ brakeman -C --skip-files plugins/
---
:skip_files:
- plugins/
```

Options passed in on the commandline have priority over configuration files.

The default config locations are `./config/brakeman.yml`, `~/.brakeman/config.yml`, and `/etc/brakeman/config.yml`

The `-c` option can be used to specify a configuration file to use.

# Continuous Integration

There is a [plugin available](http://brakemanscanner.org/docs/jenkins/) for Jenkins/Hudson.

For even more continuous testing, try the [Guard plugin](https://github.com/guard/guard-brakeman).

There are a couple [Github Actions](https://github.com/marketplace?type=actions&query=brakeman) available.

# Building

    git clone git://github.com/presidentbeef/brakeman.git
    cd brakeman
    gem build brakeman.gemspec
    gem install brakeman*.gem

# Who is Using Brakeman?

* [Code Climate](https://codeclimate.com/)
* [GitHub](https://github.com/)
* [Groupon](http://www.groupon.com/)
* [New Relic](http://newrelic.com)
* [Twitter](https://twitter.com/)

[..and more!](http://brakemanscanner.org/brakeman_users)

# Homepage/News

Website: http://brakemanscanner.org/

Twitter: https://twitter.com/brakeman

Chat: https://gitter.im/presidentbeef/brakeman

# License

Brakeman is free for non-commercial use.

See [COPYING](COPYING.md) for details.
