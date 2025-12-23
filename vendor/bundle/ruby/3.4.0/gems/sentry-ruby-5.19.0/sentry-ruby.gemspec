require_relative "lib/sentry/version"

Gem::Specification.new do |spec|
  spec.name          = "sentry-ruby"
  spec.version       = Sentry::VERSION
  spec.authors = ["Sentry Team"]
  spec.description = spec.summary = "A gem that provides a client interface for the Sentry error logger"
  spec.email = "accounts@sentry.io"
  spec.license = 'MIT'

  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.4'
  spec.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  spec.files = `git ls-files | grep -Ev '^(spec|benchmarks|examples)'`.split("\n")

  github_root_uri = 'https://github.com/getsentry/sentry-ruby'
  spec.homepage = "#{github_root_uri}/tree/#{spec.version}/#{spec.name}"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{github_root_uri}/blob/#{spec.version}/CHANGELOG.md",
    "bug_tracker_uri" => "#{github_root_uri}/issues",
    "documentation_uri" => "http://www.rubydoc.info/gems/#{spec.name}/#{spec.version}"
  }

  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", "~> 1.0", ">= 1.0.2"
  spec.add_dependency "bigdecimal"
end
