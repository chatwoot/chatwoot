# RSpec JUnit Formatter

[![Build results](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml?branch=main) 
[![Gem version](http://img.shields.io/gem/v/rspec_junit_formatter.svg)](https://rubygems.org/gems/rspec_junit_formatter)

[RSpec][rspec] 2 & 3 results that your CI can read. [Jenkins][jenkins-junit], [Buildkite][buildkite-junit], [CircleCI][circleci-junit], [Gitlab][gitlab-junit], and probably more, too.

  [rspec]: http://rspec.info/
  [jenkins-junit]: https://jenkins.io/doc/pipeline/steps/junit/
  [buildkite-junit]: https://github.com/buildkite/rspec-junit-example
  [circleci-junit]: https://circleci.com/docs/2.0/collect-test-data/
  [gitlab-junit]: https://docs.gitlab.com/ee/ci/unit_test_reports.html#ruby-example

## Usage

Install the gem:

```sh
gem install rspec_junit_formatter
```

Use it:

```sh
rspec --format RspecJunitFormatter --out rspec.xml
```

You'll get an XML file `rspec.xml` with your results in it.

You can use it in combination with other [formatters][rspec-formatters], too:

```sh
rspec --format progress --format RspecJunitFormatter --out rspec.xml
```

  [rspec-formatters]: https://relishapp.com/rspec/rspec-core/v/3-6/docs/formatters

### Using in your project with Bundler

Add it to your Gemfile if you're using [Bundler][bundler]. Put it in the same groups as rspec.

```ruby
group :test do
  gem "rspec"
  gem "rspec_junit_formatter"
end
```

Put the same arguments as the commands above in [your `.rspec`][rspec-file]:

```sh
--format RspecJunitFormatter
--out rspec.xml
```
  [bundler]: https://bundler.io
  [rspec-file]: https://relishapp.com/rspec/rspec-core/v/3-6/docs/configuration/read-command-line-configuration-options-from-files

### Parallel tests

For use with `parallel_tests`, add `$TEST_ENV_NUMBER` in the output file option (in `.rspec` or `.rspec_parallel`) to avoid concurrent process write conflicts.

```sh
--format RspecJunitFormatter
--out tmp/rspec<%= ENV["TEST_ENV_NUMBER"] %>.xml
```

The formatter includes `$TEST_ENV_NUMBER` in the test suite name within the XML, too.

### Capturing output

If you like, you can capture the standard output and error streams of each test into the `:stdout` and `:stderr` example metadata which will be added to the junit report, e.g.:

```ruby
# spec_helper.rb

RSpec.configure do |config|
  # register around filter that captures stdout and stderr
  config.around(:each) do |example|
    $stdout = StringIO.new
    $stderr = StringIO.new

    example.run

    example.metadata[:stdout] = $stdout.string
    example.metadata[:stderr] = $stderr.string

    $stdout = STDOUT
    $stderr = STDERR
  end
end
```

Note that this example captures all output from every example all the time, potentially interfering with local debugging. You might like to restrict this to only on CI, or by using [rspec filters](https://relishapp.com/rspec/rspec-core/docs/hooks/filters).

## Caveats

 * XML can only represent a [limited subset of characters][xml-charsets] which excludes null bytes and most control characters. This gem will use character entities where possible and fall back to replacing invalid characters with Ruby-like escape codes otherwise. For example, the null byte becomes `\0`.

  [xml-charsets]: https://www.w3.org/TR/xml/#charsets

## Development

Run the specs with `bundle exec rake`, which uses [Appraisal][appraisal] to run the specs against all supported versions of rspec.

  [appraisal]: https://github.com/thoughtbot/appraisal

## Releasing

Bump the gem version in the gemspec, and commit. Then `bundle exec rake build` to build a gem package, `bundle exec rake install` to install and test it locally, then `bundle exec rake release` to tag and push the commits and gem.

## License

The MIT License, see [LICENSE](./LICENSE).

## Thanks

Inspired by the work of [Diego Souza][dgvncsz0f] on [RSpec Formatters][dgvncsz0f/rspec_formatters] after frustration with [CI Reporter][ci_reporter].

  [dgvncsz0f]: https://github.com/dgvncsz0f
  [dgvncsz0f/rspec_formatters]: https://github.com/dgvncsz0f/rspec_formatters
  [ci_reporter]: https://github.com/nicksieger/ci_reporter
