$:.push File.expand_path('lib', __dir__)

require 'chatwoot_kanban/version'

Gem::Specification.new do |spec|
  spec.name        = 'chatwoot_kanban'
  spec.version     = ChatwootKanban::VERSION
  spec.authors     = ['Fabricio']
  spec.email       = ['fabriciomuaca@gmail.com']
  spec.summary     = 'Kanban module for Chatwoot — boards, columns, cards linked to conversations.'
  spec.description = 'A mountable Rails Engine that adds Kanban boards to Chatwoot ' \
                     'without touching the core code. Designed to survive upstream merges.'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.files = Dir[
    '{app,config,db,lib,frontend}/**/*',
    'MIT-LICENSE',
    'Rakefile',
    'README.md'
  ]

  spec.add_dependency 'rails', '~> 7.1'
  spec.add_dependency 'pundit'

  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'rspec-rails'
end
