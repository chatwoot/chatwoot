# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twilio-ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'twilio-ruby'
  spec.version       = Twilio::VERSION
  spec.authors       = ['Twilio API Team']
  spec.summary       = 'The official library for communicating with the Twilio REST API, '\
                       'building TwiML, and generating Twilio JWT Capability Tokens'
  spec.description   = 'The official library for communicating with the Twilio REST API, '\
                       'building TwiML, and generating Twilio JWT Capability Tokens'
  spec.homepage      = 'https://github.com/twilio/twilio-ruby'
  spec.license       = 'MIT'
  spec.metadata      = { 'documentation_uri' => 'https://www.twilio.com/docs/libraries/reference/twilio-ruby/',
                         'yard.run' => 'yri' } # use "yard" to build full HTML docs

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match?(%r{^(spec)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'
  spec.extra_rdoc_files = ['README.md', 'LICENSE']
  spec.rdoc_options = ['--line-numbers', '--inline-source', '--title', 'twilio-ruby', '--main', 'README.md']

  spec.add_dependency('jwt', '>= 1.5', '< 3.0')
  spec.add_dependency('nokogiri', '>= 1.6', '< 2.0')
  spec.add_dependency('faraday', '>= 0.9', '< 3.0')
  # Workaround for RBX <= 2.2.1, should be fixed in next version
  spec.add_dependency('rubysl') if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'

  spec.add_development_dependency 'bundler', '>= 1.5', '< 3.0'
  spec.add_development_dependency 'equivalent-xml', '~> 0.6'
  spec.add_development_dependency 'fakeweb', '~> 1.3'
  spec.add_development_dependency 'rack', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.9.9'
  spec.add_development_dependency 'logger', '~> 1.4.2'
end
