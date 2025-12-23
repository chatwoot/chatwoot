# frozen_string_literal: true

version = File.read(File.expand_path('../VERSION', __dir__)).strip

Gem::Specification.new do |s|
  # general infos
  s.name        = 'rack-protection'
  s.version     = version
  s.description = 'Protect against typical web attacks, works with all Rack apps, including Rails'
  s.homepage    = 'https://sinatrarb.com/protection/'
  s.summary     = "#{s.description}."
  s.license     = 'MIT'
  s.authors     = ['https://github.com/sinatra/sinatra/graphs/contributors']
  s.email       = 'sinatrarb@googlegroups.com'
  s.files       = Dir['lib/**/*.rb'] + [
    'License',
    'README.md',
    'Rakefile',
    'Gemfile',
    'rack-protection.gemspec'
  ]

  unless s.respond_to?(:metadata)
    raise <<-WARN
RubyGems 2.0 or newer is required to protect against public gem pushes. You can update your rubygems version by running:
  gem install rubygems-update
  update_rubygems:
  gem update --system
    WARN
  end

  s.metadata = {
    'source_code_uri' => 'https://github.com/sinatra/sinatra/tree/main/rack-protection',
    'homepage_uri' => 'http://sinatrarb.com/protection/',
    'documentation_uri' => 'https://www.rubydoc.info/gems/rack-protection',
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = '>= 2.7.8'

  # dependencies
  s.add_dependency 'base64', '>= 0.1.0'
  s.add_dependency 'logger', '>= 1.6.0'
  s.add_dependency 'rack', '>= 3.0.0', '< 4'
end
