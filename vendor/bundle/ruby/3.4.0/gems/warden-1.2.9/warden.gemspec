# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'warden/version'

Gem::Specification.new do |spec|
  spec.name = "warden"
  spec.version = Warden::VERSION
  spec.authors = ["Daniel Neighman", "Justin Smestad", "Whitney Smestad", "José Valim"]
  spec.email = %q{hasox.sox@gmail.com justin.smestad@gmail.com whitcolorado@gmail.com}
  spec.homepage = "https://github.com/hassox/warden"
  spec.summary = "An authentication library compatible with all Rack-based frameworks"
  spec.license = "MIT"
  spec.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]
  spec.add_dependency "rack", ">= 2.0.9"
end
