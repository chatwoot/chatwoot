# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rb-fsevent/version'

Gem::Specification.new do |s|
  s.name        = 'rb-fsevent'
  s.version     = FSEvent::VERSION
  s.authors     = ['Thibaud Guillaume-Gentil', 'Travis Tilley']
  s.email       = ['thibaud@thibaud.gg', 'ttilley@gmail.com']
  s.homepage    = 'http://rubygems.org/gems/rb-fsevent'
  s.summary     = 'Very simple & usable FSEvents API'
  s.description = 'FSEvents API with Signals catching (without RubyCocoa)'
  s.license     = 'MIT'

  s.metadata = {
    'source_code_uri' => 'https://github.com/thibaudgg/rb-fsevent'
  }

  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  s.require_path = 'lib'

  s.add_development_dependency 'rspec',       '~> 3.6'
  s.add_development_dependency 'guard-rspec', '~> 4.2'
  s.add_development_dependency 'rake',        '~> 12.0'
end
