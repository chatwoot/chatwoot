# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "haikunator/version"

Gem::Specification.new do |spec|
  spec.name          = "haikunator"
  spec.version       = Haikunator::VERSION
  spec.authors       = ["Usman Bashir"]
  spec.email         = ["me@usmanbashir.com"]
  spec.summary       = "Heroku-like random name generator."
  spec.description   = "Generate memorable random names to use in your apps"\
                       " or anywhere else."
  spec.homepage      = "https://github.com/usmanbashir/haikunator"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
end
