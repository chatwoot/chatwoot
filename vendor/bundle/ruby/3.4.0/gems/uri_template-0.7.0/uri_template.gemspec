Gem::Specification.new do |s|
  s.name = 'uri_template'
  s.version = '0.7.0'
  s.date = Time.now.strftime('%Y-%m-%d')
  s.authors = ["HannesG"]
  s.email = %q{hannes.georg@googlemail.com}
  s.summary = 'A templating system for URIs.'
  s.homepage = 'http://github.com/hannesg/uri_template'
  s.description = 'A templating system for URIs, which implements RFC6570 and Colon based URITemplates in a clean and straight forward way.'

  s.require_paths = ['lib']

  s.license = 'MIT'

  s.files = Dir.glob('lib/**/**/*.rb') + ['uri_template.gemspec', 'README.md', 'CHANGELOG.md']

  s.add_development_dependency 'multi_json'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler'
end
