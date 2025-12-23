# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "retriable/version"

Gem::Specification.new do |spec|
  spec.name          = "retriable"
  spec.version       = Retriable::VERSION
  spec.authors       = ["Jack Chu"]
  spec.email         = ["jack@jackchu.com"]
  spec.summary       = "Retriable is a simple DSL to retry failed code blocks with randomized exponential backoff"
  spec.description   = "Retriable is a simple DSL to retry failed code blocks with randomized exponential backoff. This is especially useful when interacting external api/services or file system calls."
  spec.homepage      = "http://github.com/kamui/retriable"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec", "~> 3"

  if RUBY_VERSION < "2.3"
    spec.add_development_dependency "ruby_dep", "~> 1.3.1"
    spec.add_development_dependency "listen", "~> 3.0.8"
  else
    spec.add_development_dependency "listen", "~> 3.1"
  end
end
