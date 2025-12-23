# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/schema/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-schema"
  spec.authors       = ["Piotr Solnica"]
  spec.email         = ["piotr.solnica@gmail.com"]
  spec.license       = "MIT"
  spec.version       = Dry::Schema::VERSION.dup

  spec.summary       = "Coercion and validation for data structures"
  spec.description   = <<~TEXT
    dry-schema provides a DSL for defining schemas with keys and rules that should be applied to
    values. It supports coercion, input sanitization, custom types and localized error messages
    (with or without I18n gem). It's also used as the schema engine in dry-validation.

  TEXT
  spec.homepage      = "https://dry-rb.org/gems/dry-schema"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-schema.gemspec",
                           "lib/**/*", "config/*.yml"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["changelog_uri"]         = "https://github.com/dry-rb/dry-schema/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]       = "https://github.com/dry-rb/dry-schema"
  spec.metadata["bug_tracker_uri"]       = "https://github.com/dry-rb/dry-schema/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1"

  # to update dependencies edit project.yml
  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "dry-configurable", "~> 1.0", ">= 1.0.1"
  spec.add_dependency "dry-core", "~> 1.1"
  spec.add_dependency "dry-initializer", "~> 3.2"
  spec.add_dependency "dry-logic", "~> 1.5"
  spec.add_dependency "dry-types", "~> 1.8"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
