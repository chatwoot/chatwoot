# frozen_string_literal: true

require File.expand_path(
  File.join('..', 'lib', 'omniauth', 'google_oauth2', 'version'),
  __FILE__
)

Gem::Specification.new do |gem|
  gem.name          = 'omniauth-google-oauth2'
  gem.version       = OmniAuth::GoogleOauth2::VERSION
  gem.license       = 'MIT'
  gem.summary       = %(A Google OAuth2 strategy for OmniAuth 1.x)
  gem.description   = %(A Google OAuth2 strategy for OmniAuth 1.x. This allows you to login to Google with your ruby app.)
  gem.authors       = ['Josh Ellithorpe', 'Yury Korolev']
  gem.email         = ['quest@mac.com']
  gem.homepage      = 'https://github.com/zquestz/omniauth-google-oauth2'

  gem.files         = `git ls-files`.split("\n")
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.2'

  gem.add_runtime_dependency 'jwt', '>= 2.0'
  gem.add_runtime_dependency 'oauth2', '~> 2.0'
  gem.add_runtime_dependency 'omniauth', '~> 2.0'
  gem.add_runtime_dependency 'omniauth-oauth2', '~> 1.8'

  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rspec', '~> 3.6'
  gem.add_development_dependency 'rubocop', '~> 0.49'
end
