$:.push File.expand_path('../lib', __FILE__)
require 'devise_two_factor/version'

Gem::Specification.new do |s|
  s.name        = 'devise-two-factor'
  s.version     = DeviseTwoFactor::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.summary     = 'Barebones two-factor authentication with Devise'
  s.homepage    = 'https://github.com/devise-two-factor/devise-two-factor'
  s.description = 'Devise-Two-Factor is a minimalist extension to Devise which offers support for two-factor authentication through the TOTP scheme.'
  s.authors     = ['Quinn Wilton']

  s.files         = `git ls-files`.split("\n").delete_if { |x| x.match('demo/*') }
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']

  s.add_runtime_dependency 'railties',       '>= 7.0', '< 8.1'
  s.add_runtime_dependency 'activesupport',  '>= 7.0', '< 8.1'
  s.add_runtime_dependency 'devise',         '~> 4.0'
  s.add_runtime_dependency 'rotp',           '~> 6.0'

  s.add_development_dependency 'activemodel'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'bundler',    '> 1.0'
  s.add_development_dependency 'rspec',      '> 3'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rake', '~> 13'
end
