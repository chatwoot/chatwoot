require_relative 'lib/web_push/version'

Gem::Specification.new do |spec|
  spec.name = 'web-push'
  spec.version = WebPush::VERSION
  spec.license = 'MIT'
  spec.authors = ['zaru', 'collimarco']
  spec.email = ['support@pushpad.xyz']

  spec.summary = 'Web Push library for Ruby (RFC8030)'
  spec.homepage = 'https://github.com/pushpad/web-push'

  spec.files = `git ls-files`.split("\n")

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'jwt', '~> 2.0'
  spec.add_dependency 'openssl', '~> 3.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
