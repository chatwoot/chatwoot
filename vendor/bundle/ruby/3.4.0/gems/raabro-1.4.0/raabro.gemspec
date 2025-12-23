
Gem::Specification.new do |s|

  s.name = 'raabro'

  s.version = File.read(
    File.expand_path('../lib/raabro.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux+flor@gmail.com' ]
  s.homepage = 'https://github.com/floraison/raabro'
  s.license = 'MIT'
  s.summary = 'a very dumb PEG parser library'

  s.description = %{
A very dumb PEG parser library, with a horrible interface.
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'README.{md,txt}',
    'CHANGELOG.{md,txt}', 'CREDITS.{md,txt}', 'LICENSE.{md,txt}',
    'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    "#{s.name}.gemspec",
  ]

  #s.add_runtime_dependency 'tzinfo'

  s.add_development_dependency 'rspec', '~> 3.7'

  s.require_path = 'lib'
end

