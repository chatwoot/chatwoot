
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "json_schemer/version"

Gem::Specification.new do |spec|
  spec.name          = "json_schemer"
  spec.version       = JSONSchemer::VERSION
  spec.authors       = ["David Harsha"]
  spec.email         = ["davishmcclurg@gmail.com"]

  spec.summary       = "JSON Schema validator. Supports drafts 4, 6, and 7."
  spec.homepage      = "https://github.com/davishmcclurg/json_schemer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|JSON-Schema-Test-Suite)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.4'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  # spec.add_development_dependency "benchmark-ips", "~> 2.7.2"
  # spec.add_development_dependency "jschema", "~> 0.2.1"
  # spec.add_development_dependency "json-schema", "~> 2.8.0"
  # spec.add_development_dependency "json_schema", "~> 0.17.0"
  # spec.add_development_dependency "json_validation", "~> 0.1.0"
  # spec.add_development_dependency "jsonschema", "~> 2.0.2"
  # spec.add_development_dependency "rj_schema", "~> 0.2.0"

  spec.add_runtime_dependency "ecma-re-validator", "~> 0.3"
  spec.add_runtime_dependency "hana", "~> 1.3"
  spec.add_runtime_dependency "uri_template", "~> 0.7"
  spec.add_runtime_dependency "regexp_parser", "~> 2.0"
end
