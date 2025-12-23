# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uglifier/version'

Gem::Specification.new do |spec|
  spec.name = "uglifier"
  spec.version = Uglifier::VERSION
  spec.authors = ["Ville Lautanala"]
  spec.email = ["lautis@gmail.com"]
  spec.homepage = "http://github.com/lautis/uglifier"
  spec.summary = "Ruby wrapper for UglifyJS JavaScript compressor"
  spec.description = "Uglifier minifies JavaScript files by wrapping UglifyJS to be accessible in Ruby"
  spec.license = "MIT"

  spec.required_ruby_version = '>= 1.9.3'

  spec.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md"
  ]

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec|vendor|gemfiles|patches)/})
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "execjs", [">= 0.3.0", "< 3"]
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "sourcemap", "~> 0.1.1"
end
