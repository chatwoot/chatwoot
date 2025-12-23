# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "spring-watcher-listen"
  spec.version       = "2.1.0"
  spec.authors       = ["Jon Leighton"]
  spec.email         = ["j@jonathanleighton.com"]
  spec.summary       = %q{Makes spring watch files using the listen gem.}
  spec.homepage      = "https://github.com/jonleighton/spring-watcher-listen"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activesupport"

  spec.add_dependency "spring", ">= 4"
  spec.add_dependency "listen", ">= 2.7", '< 4.0'
end
