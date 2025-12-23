$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'shoulda/matchers/version'

Gem::Specification.new do |s|
  s.name        = 'shoulda-matchers'
  s.version     = Shoulda::Matchers::VERSION.dup
  s.authors     = [
    'Tammer Saleh',
    'Joe Ferris',
    'Ryan McGeary',
    'Dan Croak',
    'Matt Jankowski',
    'Stafford Brunk',
    'Elliot Winkler',
  ]
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.email       = 'support@thoughtbot.com'
  s.homepage    = 'https://matchers.shoulda.io/'
  s.summary     = 'Simple one-liner tests for common Rails functionality'
  s.license     = 'MIT'
  s.description = <<~DESC.tr("\n", ' ').squeeze(' ')
    Shoulda Matchers provides RSpec- and Minitest-compatible one-liners to test
    common Rails functionality that, if written by hand, would be much
    longer, more complex, and error-prone.
  DESC

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/thoughtbot/shoulda-matchers/issues',
    'changelog_uri' => 'https://github.com/thoughtbot/shoulda-matchers/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://matchers.shoulda.io/docs',
    'homepage_uri' => 'https://matchers.shoulda.io',
    'source_code_uri' => 'https://github.com/thoughtbot/shoulda-matchers',
  }

  s.files = Dir['{docs,lib}/**/*', 'README.md', 'LICENSE',
    'shoulda-matchers.gemspec']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.6.0'
  s.add_dependency('activesupport', '>= 5.2.0')
end
