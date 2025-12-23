# -*- encoding: utf-8 -*-
# stub: docile 1.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "docile".freeze
  s.version = "1.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ms-ati/docile/blob/main/HISTORY.md", "homepage_uri" => "https://ms-ati.github.io/docile/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/ms-ati/docile" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Marc Siegel".freeze]
  s.date = "2024-07-25"
  s.description = "Docile treats the methods of a given ruby object as a DSL (domain specific language) within a given block. \n\nKiller feature: you can also reference methods, instance variables, and local variables from the original (non-DSL) context within the block. \n\nDocile releases follow Semantic Versioning as defined at semver.org.".freeze
  s.email = "marc@usainnov.com".freeze
  s.homepage = "https://ms-ati.github.io/docile/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Docile keeps your Ruby DSLs tame and well-behaved.".freeze

  s.installed_by_version = "3.6.7".freeze
end
