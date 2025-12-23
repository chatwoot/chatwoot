# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sassc/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "sassc-rails"
  spec.version       = SassC::Rails::VERSION
  spec.authors       = ["Ryan Boland"]
  spec.email         = ["ryan@tanookilabs.com"]
  spec.summary       = %q{Integrate SassC-Ruby into Rails.}
  spec.description   = %q{Integrate SassC-Ruby into Rails.}
  spec.homepage      = "https://github.com/sass/sassc-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'pry'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'mocha'

  spec.add_dependency "sassc", ">= 2.0"
  spec.add_dependency "tilt"

  spec.add_dependency 'railties', '>= 4.0.0'
  spec.add_dependency 'sprockets', '> 3.0'
  spec.add_dependency 'sprockets-rails'
end
