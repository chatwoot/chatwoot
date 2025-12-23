# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/types/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-types"
  spec.authors       = ["Piotr Solnica"]
  spec.email         = ["piotr.solnica@gmail.com"]
  spec.license       = "MIT"
  spec.version       = Dry::Types::VERSION.dup

  spec.summary       = "Type system for Ruby supporting coercions, constraints and complex types like structs, value objects, enums etc"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-types"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-types.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["changelog_uri"]         = "https://github.com/dry-rb/dry-types/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]       = "https://github.com/dry-rb/dry-types"
  spec.metadata["bug_tracker_uri"]       = "https://github.com/dry-rb/dry-types/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1"

  # to update dependencies edit project.yml
  spec.add_dependency "bigdecimal", "~> 3.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "dry-core", "~> 1.0"
  spec.add_dependency "dry-inflector", "~> 1.0"
  spec.add_dependency "dry-logic", "~> 1.4"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
