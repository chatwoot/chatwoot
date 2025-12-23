# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'uniform_notifier/version'

Gem::Specification.new do |s|
  s.name        = 'uniform_notifier'
  s.version     = UniformNotifier::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Richard Huang']
  s.email       = ['flyerhzm@gmail.com']
  s.homepage    = 'http://rubygems.org/gems/uniform_notifier'
  s.summary     = 'uniform notifier for rails logger, customized logger, javascript alert, javascript console and xmpp'
  s.description = 'uniform notifier for rails logger, customized logger, javascript alert, javascript console and xmpp'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.3'

  s.add_development_dependency 'rspec', ['> 0']
  s.add_development_dependency 'slack-notifier', ['>= 1.0']
  s.add_development_dependency 'xmpp4r', ['= 0.5']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  if s.respond_to?(:metadata)
    s.metadata['changelog_uri'] = 'https://github.com/flyerhzm/uniform_notifier/blob/master/CHANGELOG.md'
    s.metadata['source_code_uri'] = 'https://github.com/flyerhzm/uniform_notifier'
    s.metadata['bug_tracker_uri'] = 'https://github.com/flyerhzm/uniform_notifier/issues'
  end
end
