# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "childprocess/version"

Gem::Specification.new do |s|
  s.name        = "childprocess"
  s.version     = ChildProcess::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jari Bakken", "Eric Kessler", "Shane da Silva"]
  s.email       = ["morrow748@gmail.com", "shane@dasilva.io"]
  s.homepage    = "https://github.com/enkessler/childprocess"
  s.summary     = %q{A simple and reliable solution for controlling external programs running in the background on any Ruby / OS combination.}
  s.description = %q{This gem aims at being a simple and reliable solution for controlling external programs running in the background on any Ruby / OS combination.}

  s.license           = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.4.0'

  s.add_dependency "logger", "~> 1.5"

  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "yard", "~> 0.0"
  s.add_development_dependency 'coveralls', '< 1.0'
end
