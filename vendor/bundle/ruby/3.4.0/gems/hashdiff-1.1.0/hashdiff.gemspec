# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'hashdiff/version'

Gem::Specification.new do |s|
  s.name        = 'hashdiff'
  s.version     = Hashdiff::VERSION
  s.license     = 'MIT'
  s.summary     = ' Hashdiff is a diff lib to compute the smallest difference between two hashes. '
  s.description = ' Hashdiff is a diff lib to compute the smallest difference between two hashes. '

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- Appraisals {spec}/*`.split("\n")

  s.require_paths = ['lib']
  s.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  s.authors = ['Liu Fengyun']
  s.email   = ['liufengyunchina@gmail.com']

  s.homepage = 'https://github.com/liufengyun/hashdiff'

  s.add_development_dependency('bluecloth')
  s.add_development_dependency('rspec', '~> 3.5')
  s.add_development_dependency('rubocop', '>= 1.52.1') # earliest version that works with Ruby 3.3
  s.add_development_dependency('rubocop-rspec', '> 1.16.0') # https://github.com/rubocop/rubocop-rspec/issues/461
  s.add_development_dependency('yard')

  if s.respond_to?(:metadata)
    s.metadata = {
      'bug_tracker_uri' => 'https://github.com/liufengyun/hashdiff/issues',
      'changelog_uri' => 'https://github.com/liufengyun/hashdiff/blob/master/changelog.md',
      'documentation_uri' => 'https://www.rubydoc.info/gems/hashdiff',
      'homepage_uri' => 'https://github.com/liufengyun/hashdiff',
      'source_code_uri' => 'https://github.com/liufengyun/hashdiff'
    }
  end
end
