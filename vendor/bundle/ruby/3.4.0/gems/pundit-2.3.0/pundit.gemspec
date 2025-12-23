# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pundit/version"

Gem::Specification.new do |gem|
  gem.name          = "pundit"
  gem.version       = Pundit::VERSION
  gem.authors       = ["Jonas Nicklas", "Varvet AB"]
  gem.email         = ["jonas.nicklas@gmail.com", "dev@elabs.se"]
  gem.description   = "Object oriented authorization for Rails applications"
  gem.summary       = "OO authorization for Rails"
  gem.homepage      = "https://github.com/varvet/pundit"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activesupport", ">= 3.0.0"
  gem.add_development_dependency "actionpack", ">= 3.0.0"
  gem.add_development_dependency "activemodel", ">= 3.0.0"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "railties", ">= 3.0.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", ">= 3.0.0"
  gem.add_development_dependency "rubocop", "1.24.0"
  gem.add_development_dependency "simplecov", ">= 0.17.0"
  gem.add_development_dependency "yard"
end
