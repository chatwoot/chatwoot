# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-cli"
  spec.authors       = ["Luca Guidi"]
  spec.email         = ["me@lucaguidi.com"]
  spec.license       = "MIT"
  spec.version       = Dry::CLI::VERSION.dup

  spec.summary       = "Common framework to build command line interfaces with Ruby"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-cli"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-cli.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/dry-rb/dry-cli/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/dry-rb/dry-cli"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/dry-rb/dry-cli/issues"

  spec.required_ruby_version = ">= 2.4.0"

  # to update dependencies edit project.yml

  spec.add_development_dependency "bundler", ">= 1.6", "< 3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "rubocop", "~> 0.82"
  spec.add_development_dependency "simplecov", "~> 0.17.1"
end
