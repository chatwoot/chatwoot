# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "barnes/version"

Gem::Specification.new do |spec|
  spec.name          = "barnes"
  spec.version       = Barnes::VERSION
  spec.authors       = ["schneems"]
  spec.email         = ["richard.schneeman@gmail.com"]

  spec.summary       = 'Ruby GC stats => StatsD'
  spec.description   = 'Report GC usage data to StatsD.'
  spec.homepage      = 'https://github.com/heroku/barnes'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency 'statsd-ruby', '~> 1.1'
  spec.add_runtime_dependency 'multi_json', '~> 1'

  spec.add_development_dependency 'rack',     '~> 2'
  spec.add_development_dependency 'rake',     '>= 10'
  spec.add_development_dependency 'minitest', '~> 5.3'
  spec.add_development_dependency "puma",     '~> 3.12'
  spec.add_development_dependency "wait_for_it",     '~> 0.1'
end
