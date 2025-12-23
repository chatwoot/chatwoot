# encoding: utf-8
require './lib/crass/version'

Gem::Specification.new do |s|
  s.name        = 'crass'
  s.summary     = 'CSS parser based on the CSS Syntax Level 3 spec.'
  s.description = 'Crass is a pure Ruby CSS parser based on the CSS Syntax Level 3 spec.'
  s.version     = Crass::VERSION
  s.authors     = ['Ryan Grove']
  s.email       = ['ryan@wonko.com']
  s.homepage    = 'https://github.com/rgrove/crass/'
  s.license     = 'MIT'

  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/rgrove/crass/issues',
    'changelog_uri'     => "https://github.com/rgrove/crass/blob/v#{s.version}/HISTORY.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/crass/#{s.version}",
    'source_code_uri'   => "https://github.com/rgrove/crass/tree/v#{s.version}",
  }

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.2')

  s.require_paths = ['lib']

  s.files = `git ls-files -z`.split("\x0").grep_v(%r{^test/})

  # Development dependencies.
  s.add_development_dependency 'minitest', '~> 5.0.8'
  s.add_development_dependency 'rake',     '~> 10.1.0'
end
