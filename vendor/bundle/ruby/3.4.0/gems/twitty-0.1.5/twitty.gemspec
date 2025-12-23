lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twitty/version'

Gem::Specification.new do |spec|
  spec.name          = 'twitty'
  spec.version       = Twitty::VERSION
  spec.authors       = ['Subin T P', 'Pranav Raj S', 'Sojan Jose']
  spec.email         = ['hello@thoughtwoot.com', 'subin@thoughtwoot.com', 'pranav@thoughtwoot.com', 'sojan@thoughtwoot.com']

  spec.summary       = 'Twitter API wrapper'
  spec.description   = 'Twitty makes working with the twitter account subscriptions APIs much easier'
  spec.homepage      = 'https://www.chatwoot.com'
  spec.license       = 'MIT'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/chatwoot/twitty/issues',
    'homepage_uri' => 'https://github.com/chatwoot/twitty',
    'source_code_uri' => 'https://github.com/chatwoot/twitty',
    'rubygems_mfa_required' => 'false'
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_runtime_dependency 'oauth'
end
