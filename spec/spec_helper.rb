require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Set default test encryption keys if not already set
ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'] ||= 'test_sAK7479yQQvk0574SPM9RZFi9xx3dlBY'
ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'] ||= 'test_t8mg48yhHqOaAH7R2HA4SDDsXWcyWBYL'
ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'] ||= 'test_bsfGUb0GEmghCU5HZlBjILZwoMjypLpS'

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
