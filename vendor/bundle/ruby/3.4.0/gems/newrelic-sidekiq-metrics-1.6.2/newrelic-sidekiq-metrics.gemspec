lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'newrelic_sidekiq_metrics/version'

Gem::Specification.new do |spec|
  spec.name = 'newrelic-sidekiq-metrics'
  spec.version = NewrelicSidekiqMetrics::VERSION
  spec.authors = ['Krzysztof Knapik', 'RenoFi Engineering Team']
  spec.email = ['knapo@knapo.net', 'engineering@renofi.com']

  spec.summary = 'Implements recording Sidekiq stats to New Relic metrics.'
  spec.homepage = 'https://github.com/RenoFi/newrelic-sidekiq-metrics'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = 'https://github.com/RenoFi/newrelic-sidekiq-metrics'
  spec.metadata['source_code_uri'] = 'https://github.com/RenoFi/newrelic-sidekiq-metrics'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(bin/|spec/|\.rub)}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'newrelic_rpm', '>= 8.0.0'
  spec.add_dependency 'sidekiq'
end
