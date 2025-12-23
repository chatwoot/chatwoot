# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'slack/version'

Gem::Specification.new do |s|
  s.name = 'slack-ruby-client'
  s.bindir = 'bin'
  s.executables << 'slack'
  s.version = Slack::VERSION
  s.authors = ['Daniel Doubrovkine']
  s.email = 'dblock@dblock.org'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.7'
  s.required_rubygems_version = '>= 1.3.6'
  s.files = `git ls-files`.split("\n").grep_v(%r{^spec/})
  s.require_paths = ['lib']
  s.homepage = 'http://github.com/slack-ruby/slack-ruby-client'
  s.licenses = ['MIT']
  s.summary = 'Slack Web and RealTime API client.'
  s.add_dependency 'faraday', '>= 2.0.1'
  s.add_dependency 'faraday-mashify'
  s.add_dependency 'faraday-multipart'
  s.add_dependency 'gli'
  s.add_dependency 'hashie'
  s.add_dependency 'logger'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['changelog_uri'] = 'https://github.com/slack-ruby/slack-ruby-client/blob/master/CHANGELOG.md'
end
