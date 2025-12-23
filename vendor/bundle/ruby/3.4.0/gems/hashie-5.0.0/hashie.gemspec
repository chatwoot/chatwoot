require File.expand_path('../lib/hashie/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'hashie'
  gem.version       = Hashie::VERSION
  gem.authors       = ['Michael Bleigh', 'Jerry Cheung']
  gem.email         = ['michael@intridea.com', 'jollyjerry@gmail.com']
  gem.description   = 'Hashie is a collection of classes and mixins that make hashes more powerful.'
  gem.summary       = 'Your friendly neighborhood hash library.'
  gem.homepage      = 'https://github.com/hashie/hashie'
  gem.license       = 'MIT'

  gem.require_paths = ['lib']
  gem.files = %w[.yardopts CHANGELOG.md CONTRIBUTING.md LICENSE README.md UPGRADING.md]
  gem.files += %w[Rakefile hashie.gemspec]
  gem.files += Dir['lib/**/*.rb']

  if gem.respond_to?(:metadata)
    gem.metadata = {
      'bug_tracker_uri'   => 'https://github.com/hashie/hashie/issues',
      'changelog_uri'     => 'https://github.com/hashie/hashie/blob/master/CHANGELOG.md',
      'documentation_uri' => 'https://www.rubydoc.info/gems/hashie',
      'source_code_uri'   => 'https://github.com/hashie/hashie'
    }
  end

  gem.add_development_dependency 'bundler'
end
