require 'simplecov'
require 'webmock/rspec'

SimpleCov.start 'rails'
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

  def skip_unless_response_bot_enabled_test_environment
    # Tests skipped using this method should be added to .github/workflows/run_response_bot_spec.yml
    # Manage response bot tests in your local environment using the following commands:
    # Enable response bot for tests
    # RAILS_ENV=test bundle exec rails runner "Features::ResponseBotService.new.enable_in_installation"
    # Disable response bot for tests
    # RAILS_ENV=test bundle exec rails runner "Features::ResponseBotService.new.disable_in_installation"
    skip('Skipping since vector is not enabled in this environment') unless Features::ResponseBotService.new.vector_extension_enabled?
  end
end
