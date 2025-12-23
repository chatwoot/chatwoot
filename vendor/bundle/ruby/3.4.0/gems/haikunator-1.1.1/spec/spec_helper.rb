require "coveralls"
Coveralls.wear!

require "haikunator"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Use the specified formatter
  config.formatter = :documentation

  # Print top 2 slowest examples
  config.profile_examples = 2

  # Run specs in random order
  config.order = :random
end
