# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hash_diff/version'

Gem::Specification.new do |spec|
  spec.name          = "hash_diff"
  spec.version       = HashDiff::VERSION
  spec.authors       = ["Coding Zeal", "Adam Cuppy", "Mike Bianco"]
  spec.email         = ["info@codingzeal.com", "mike@mikebian.co"]
  spec.description   = %q{Diff tool for deep Ruby hash comparison}
  spec.summary       = %q{Deep Ruby Hash comparison}
  spec.homepage      = "https://github.com/CodingZeal/hash_diff"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1"
end
