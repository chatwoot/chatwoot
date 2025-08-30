if ENV['CI'] == 'true' || ENV['CIRCLECI'] == 'true'
  require 'simplecov'
  require 'simplecov_json_formatter'
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
  SimpleCov.start 'rails' do
    SimpleCov.coverage_dir 'coverage'
  end
end
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  def with_modified_env(options, &)
    ClimateControl.modify(options, &)
  end
end
