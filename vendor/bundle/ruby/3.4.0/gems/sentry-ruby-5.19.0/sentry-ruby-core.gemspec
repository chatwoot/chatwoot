require_relative "lib/sentry/version"

Gem::Specification.new do |spec|
  spec.name          = "sentry-ruby-core"
  spec.version       = Sentry::VERSION
  spec.authors = ["Sentry Team"]
  spec.description = spec.summary = "A gem that provides a client interface for the Sentry error logger"
  spec.email = "accounts@sentry.io"
  spec.license = 'MIT'
  spec.homepage = "https://github.com/getsentry/sentry-ruby"

  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.4'
  spec.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  spec.files = `git ls-files | grep -Ev '^(spec|benchmarks|examples)'`.split("\n")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.add_dependency "sentry-ruby", Sentry::VERSION
  spec.add_dependency "concurrent-ruby"
end
