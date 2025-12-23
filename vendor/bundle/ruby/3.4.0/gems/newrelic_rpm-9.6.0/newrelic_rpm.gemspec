# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'new_relic/version'
require 'new_relic/latest_changes'

Gem::Specification.new do |s|
  s.name = 'newrelic_rpm'
  s.version = NewRelic::VERSION::STRING
  s.required_ruby_version = '>= 2.4.0'
  s.required_rubygems_version = Gem::Requirement.new('> 1.3.1') if s.respond_to?(:required_rubygems_version=)
  s.authors = ['Tanna McClure', 'Kayla Reopelle', 'James Bunch', 'Hannah Ramadan']
  s.licenses = ['Apache-2.0']
  s.description = <<~EOS
    New Relic is a performance management system, developed by New Relic,
    Inc (http://www.newrelic.com).  New Relic provides you with deep
    information about the performance of your web application as it runs
    in production. The New Relic Ruby agent is dual-purposed as a either a
    Gem or plugin, hosted on
    https://github.com/newrelic/newrelic-ruby-agent/
  EOS
  s.email = 'support@newrelic.com'
  # TODO: MAJOR VERSION - remove newrelic_cmd, deprecated since version 2.13
  s.executables = %w[newrelic_cmd newrelic nrdebug]
  s.extra_rdoc_files = [
    'CHANGELOG.md',
    'LICENSE',
    'README.md',
    'CONTRIBUTING.md',
    'newrelic.yml'
  ]

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/newrelic/newrelic-ruby-agent/issues',
    'changelog_uri' => 'https://github.com/newrelic/newrelic-ruby-agent/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://docs.newrelic.com/docs/agents/ruby-agent',
    'source_code_uri' => 'https://github.com/newrelic/newrelic-ruby-agent',
    'homepage_uri' => 'https://newrelic.com/ruby'
  }

  reject_list = File.read(File.expand_path('../.build_ignore', __FILE__)).split("\n")
  file_list = `git ls-files -z`.split("\x0").reject { |f| reject_list.any? { |rf| f.start_with?(rf) } }
  # test/agent_helper.rb is a requirement for the NewRelic::Agent.require_test_helper public API
  test_helper_path = 'test/agent_helper.rb'
  file_list << test_helper_path
  s.files = file_list

  s.homepage = 'https://github.com/newrelic/newrelic-ruby-agent'
  s.require_paths = ['lib']
  s.summary = 'New Relic Ruby Agent'

  s.add_dependency 'base64'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'feedjira', '3.2.1' unless ENV['CI'] || RUBY_VERSION < '2.5' # for Gabby
  s.add_development_dependency 'httparty' unless ENV['CI'] # for perf tests and Gabby
  s.add_development_dependency 'minitest', "#{RUBY_VERSION >= '2.7.0' ? '5.3.3' : '4.7.5'}"
  s.add_development_dependency 'minitest-stub-const', '0.6'
  s.add_development_dependency 'mocha', '~> 1.16'
  s.add_development_dependency 'pry' if ENV['ENABLE_PRY']
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rake', '12.3.3'

  s.add_development_dependency 'rubocop', '1.54' unless ENV['CI'] && RUBY_VERSION < '3.0.0'
  s.add_development_dependency 'rubocop-ast', '1.28.1' unless ENV['CI'] && RUBY_VERSION < '3.0.0'
  s.add_development_dependency 'rubocop-minitest', '0.27.0' unless ENV['CI'] && RUBY_VERSION < '3.0.0'
  s.add_development_dependency 'rubocop-performance', '1.16.0' unless ENV['CI'] && RUBY_VERSION < '3.0.0'
  s.add_development_dependency 'rubocop-rake', '0.6.0' unless ENV['CI'] && RUBY_VERSION < '3.0.0'

  s.add_development_dependency 'simplecov' if RUBY_VERSION >= '2.7.0'
  s.add_development_dependency 'thor' unless ENV['CI']
  s.add_development_dependency 'warning'
  s.add_development_dependency 'yard'
end
