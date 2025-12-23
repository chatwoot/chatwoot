# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/cors/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack-cors'
  spec.version       = Rack::Cors::VERSION
  spec.authors       = ['Calvin Yu']
  spec.email         = ['me@sourcebender.com']
  spec.description   = 'Middleware that will make Rack-based apps CORS compatible. Fork the project here: https://github.com/cyu/rack-cors'
  spec.summary       = 'Middleware for enabling Cross-Origin Resource Sharing in Rack apps'
  spec.homepage      = 'https://github.com/cyu/rack-cors'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR).reject { |f| (f == '.gitignore') || f =~ /^examples/ }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '>= 2.0.0'
  spec.add_development_dependency 'bundler', '>= 1.16.0', '< 3'
  spec.add_development_dependency 'minitest', '~> 5.11.0'
  spec.add_development_dependency 'mocha', '~> 1.6.0'
  spec.add_development_dependency 'pry', '~> 0.12'
  spec.add_development_dependency 'rack-test', '~> 1.1.0'
  spec.add_development_dependency 'rake', '~> 12.3.0'
  spec.add_development_dependency 'rubocop', '~> 0.80.1'
end
