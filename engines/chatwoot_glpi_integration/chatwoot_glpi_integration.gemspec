$:.push File.expand_path('lib', __dir__)

require 'chatwoot_glpi_integration/version'

Gem::Specification.new do |spec|
  spec.name        = 'chatwoot_glpi_integration'
  spec.version     = ChatwootGlpiIntegration::VERSION
  spec.authors     = ['Fabricio']
  spec.email       = ['fabriciomuaca@gmail.com']
  spec.summary     = 'Two-way GLPI 11.x integration for Chatwoot.'
  spec.description = 'A mountable Rails Engine that links Chatwoot conversations ' \
                     'and Kanban cards to GLPI tickets via OAuth2 and webhooks.'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.files = Dir[
    '{app,config,db,lib,frontend}/**/*',
    'MIT-LICENSE',
    'Rakefile',
    'README.md'
  ]

  spec.add_dependency 'rails',       '~> 7.1'
  spec.add_dependency 'faraday',     '~> 2.7'
  spec.add_dependency 'faraday-retry'

  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'factory_bot_rails'
end
