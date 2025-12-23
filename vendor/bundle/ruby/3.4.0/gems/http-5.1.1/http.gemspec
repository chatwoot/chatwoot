# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "http/version"

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Arcieri", "Erik Michaels-Ober", "Alexey V. Zapparov", "Zachary Anker"]
  gem.email         = ["bascule@gmail.com"]

  gem.description   = <<-DESCRIPTION.strip.gsub(/\s+/, " ")
    An easy-to-use client library for making requests from Ruby.
    It uses a simple method chaining system for building requests,
    similar to Python's Requests.
  DESCRIPTION

  gem.summary       = "HTTP should be easy"
  gem.homepage      = "https://github.com/httprb/http"
  gem.licenses      = ["MIT"]

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "http"
  gem.require_paths = ["lib"]
  gem.version       = HTTP::VERSION

  gem.required_ruby_version = ">= 2.6"

  gem.add_runtime_dependency "addressable",    "~> 2.8"
  gem.add_runtime_dependency "http-cookie",    "~> 1.0"
  gem.add_runtime_dependency "http-form_data", "~> 2.2"
  gem.add_runtime_dependency "llhttp-ffi",     "~> 0.4.0"

  gem.add_development_dependency "bundler", "~> 2.0"

  gem.metadata = {
    "source_code_uri"       => "https://github.com/httprb/http",
    "wiki_uri"              => "https://github.com/httprb/http/wiki",
    "bug_tracker_uri"       => "https://github.com/httprb/http/issues",
    "changelog_uri"         => "https://github.com/httprb/http/blob/v#{HTTP::VERSION}/CHANGES.md",
    "rubygems_mfa_required" => "true"
  }
end
