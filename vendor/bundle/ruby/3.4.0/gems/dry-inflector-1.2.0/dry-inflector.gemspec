# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/inflector/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-inflector"
  spec.authors       = ["Luca Guidi", "Andrii Savchenko", "Abinoam P. Marques Jr."]
  spec.email         = ["me@lucaguidi.com", "andrey@aejis.eu", "abinoam@gmail.com"]
  spec.license       = "MIT"
  spec.version       = Dry::Inflector::VERSION.dup

  spec.summary       = "String inflections for dry-rb"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-inflector"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-inflector.gemspec",
                           "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["changelog_uri"]         = "https://github.com/dry-rb/dry-inflector/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]       = "https://github.com/dry-rb/dry-inflector"
  spec.metadata["bug_tracker_uri"]       = "https://github.com/dry-rb/dry-inflector/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1"
end
