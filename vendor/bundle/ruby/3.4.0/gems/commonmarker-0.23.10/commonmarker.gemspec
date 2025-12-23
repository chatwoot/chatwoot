# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "commonmarker/version"

Gem::Specification.new do |s|
  s.name = "commonmarker"
  s.version = CommonMarker::VERSION
  s.summary = "CommonMark parser and renderer. Written in C, wrapped in Ruby."
  s.description = "A fast, safe, extensible parser for CommonMark. This wraps the official libcmark library."
  s.authors = ["Garen Torikian", "Ashe Connor"]
  s.homepage = "https://github.com/gjtorikian/commonmarker"
  s.license = "MIT"

  s.files         = ["LICENSE.txt", "README.md", "Rakefile", "commonmarker.gemspec", "bin/commonmarker"]
  s.files        += Dir.glob("lib/**/*.rb")
  s.files        += Dir.glob("ext/commonmarker/*.*")
  s.extensions    = ["ext/commonmarker/extconf.rb"]

  s.executables = ["commonmarker"]
  s.require_paths = ["lib", "ext"]
  s.required_ruby_version = [">= 2.6", "< 4.0"]

  s.metadata["rubygems_mfa_required"] = "true"

  s.rdoc_options += ["-x", "ext/commonmarker/cmark/.*"]

  s.add_development_dependency("awesome_print")
  s.add_development_dependency("json", "~> 2.3")
  s.add_development_dependency("minitest", "~> 5.6")
  s.add_development_dependency("minitest-focus", "~> 1.1")
  s.add_development_dependency("rake")
  s.add_development_dependency("rake-compiler", "~> 0.9")
  s.add_development_dependency("rdoc", "~> 6.2")
  s.add_development_dependency("rubocop")
  s.add_development_dependency("rubocop-standard")
end
