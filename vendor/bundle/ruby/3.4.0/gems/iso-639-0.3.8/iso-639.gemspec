# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'iso-639'
  s.version = '0.3.8'
  s.licenses = ['MIT']
  s.summary = 'ISO 639-1 and ISO 639-2 language code entries and convenience methods.'
  s.description = 'ISO 639-1 and ISO 639-2 language code entries and convenience methods.'
  s.authors = ['William Melody']
  s.email = 'hi@williammelody.com'
  s.extra_rdoc_files = [
    'LICENSE',
    'README.md'
  ]
  s.files = [
    '.document',
    'Gemfile',
    'Gemfile.lock',
    'LICENSE',
    'README.md',
    'Rakefile',
    'iso-639.gemspec',
    'lib/data/ISO-639-2_utf-8.txt',
    'lib/iso-639.rb',
    'test/helper.rb',
    'test/test_iso_639.rb'
  ]
  s.homepage = 'http://github.com/xwmx/iso-639'
  s.require_paths = ['lib']
  s.add_dependency('csv')
  s.add_development_dependency('minitest',  '~> 5', '>= 0')
  s.add_development_dependency('mocha',     '~> 1', '>= 0')
  s.add_development_dependency('rdoc',      '~> 6', '>= 0')
  s.add_development_dependency('rubocop',   '~> 0', '>= 0.49.0')
  s.add_development_dependency('test-unit', '~> 3', '>= 0')
  s.required_ruby_version = '>= 2.3'
end
