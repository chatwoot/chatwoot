# coding: utf-8

require_relative 'lib/acts-as-taggable-on/version'

Gem::Specification.new do |gem|
  gem.name          = 'acts-as-taggable-on'
  gem.version       = ActsAsTaggableOn::VERSION
  gem.authors       = ['Michael Bleigh', 'Joost Baaij']
  gem.email         = %w(michael@intridea.com joost@spacebabies.nl)
  gem.description   = %q{With ActsAsTaggableOn, you can tag a single model on several contexts, such as skills, interests, and awards. It also provides other advanced functionality.}
  gem.summary       = 'Advanced tagging for Rails.'
  gem.homepage      = 'https://github.com/mbleigh/acts-as-taggable-on'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ['lib']
  gem.required_ruby_version     = '>= 3.2.0'

  if File.exist?('UPGRADING.md')
    gem.post_install_message = File.read('UPGRADING.md')
  end

  gem.add_runtime_dependency 'activerecord', '>= 7.1', '< 8.1'
  gem.add_runtime_dependency 'zeitwerk', '>= 2.4', '< 3.0'

  gem.add_development_dependency 'rspec-rails'
  gem.add_development_dependency 'rspec-its'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'barrier'
  gem.add_development_dependency 'database_cleaner'
end
