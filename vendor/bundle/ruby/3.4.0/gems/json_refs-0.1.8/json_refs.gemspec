# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "json_refs/version"

Gem::Specification.new do |spec|
  spec.name          = "json_refs"
  spec.version       = JsonRefs::VERSION
  spec.authors       = ["Makoto Tajitsu"]
  spec.email         = ["makoto_tajitsu@hotmail.co.jp"]

  spec.summary       = "Dereference JSON Pointer"
  spec.description   = "Dereference JSON Pointer"
  spec.homepage      = "https://github.com/tzmfreedom/json_refs"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "hana"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
