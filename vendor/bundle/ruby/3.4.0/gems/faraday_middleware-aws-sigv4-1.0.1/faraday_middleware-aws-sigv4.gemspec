# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'faraday_middleware-aws-sigv4'
  spec.version       = '1.0.1'
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@winebarrel.jp']

  spec.summary       = 'Faraday middleware for AWS Signature Version 4 using aws-sigv4.'
  spec.description   = 'Faraday middleware for AWS Signature Version 4 using aws-sigv4.'
  spec.homepage      = 'https://github.com/winebarrel/faraday_middleware-aws-sigv4'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'aws-sigv4', '~> 1.0'
  spec.add_dependency 'faraday', '>= 2.0', '< 3'

  spec.add_development_dependency 'appraisal', '>= 2.2'
  spec.add_development_dependency 'aws-sdk-core', '>= 3.124.0'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '>= 1.36.0'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-lcov'
  spec.add_development_dependency 'timecop'
  spec.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
