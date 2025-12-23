# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "highline/version"

Gem::Specification.new do |spec|
  spec.name        = "highline"
  spec.version     = HighLine::VERSION
  spec.author      = "James Edward Gray II"
  spec.email       = "james@graysoftinc.com"

  spec.summary     = "HighLine is a high-level command-line IO library."
  spec.description = <<DESCRIPTION
A high-level IO library that provides validation, type conversion, and more for
command-line interfaces. HighLine also includes a complete menu system that can
crank out anything from simple list selection to complete shells with just
minutes of work.
DESCRIPTION
  spec.homepage    = "https://github.com/JEG2/highline"
  spec.license     = "Ruby"

  spec.files       = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files = %w[README.md TODO Changelog.md LICENSE]

  spec.required_ruby_version = ">= 2.3"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
