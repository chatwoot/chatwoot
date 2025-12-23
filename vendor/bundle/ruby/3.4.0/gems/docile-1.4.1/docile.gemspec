# frozen_string_literal: true

require_relative "lib/docile/version"

Gem::Specification.new do |s|
  s.name        = "docile"
  s.version     = Docile::VERSION
  s.author      = "Marc Siegel"
  s.email       = "marc@usainnov.com"
  s.homepage    = "https://ms-ati.github.io/docile/"
  s.summary     = "Docile keeps your Ruby DSLs tame and well-behaved."
  s.description = "Docile treats the methods of a given ruby object as a DSL "\
                  "(domain specific language) within a given block. \n\n"\
                  "Killer feature: you can also reference methods, instance "\
                  "variables, and local variables from the original (non-DSL) "\
                  "context within the block. \n\n"\
                  "Docile releases follow Semantic Versioning as defined at "\
                  "semver.org."
  s.license     = "MIT"

  # Specify oldest supported Ruby version (2.5 to support JRuby 9.2.17.0)
  s.required_ruby_version = ">= 2.5.0"

  # Files included in the gem
  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.require_paths = ["lib"]

  s.metadata = {
    "homepage_uri" => "https://ms-ati.github.io/docile/",
    "changelog_uri" => "https://github.com/ms-ati/docile/blob/main/HISTORY.md",
    "source_code_uri" => "https://github.com/ms-ati/docile",
    "rubygems_mfa_required" => "true",
  }
end
