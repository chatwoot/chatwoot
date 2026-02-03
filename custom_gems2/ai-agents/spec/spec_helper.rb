# frozen_string_literal: true

require "simplecov"

live_llm_requested = ENV["RUN_LIVE_LLM"] || ARGV.any? { |arg| arg.include?("live_llm") }

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/examples/"
  add_filter "/bin/"
  add_filter "/sig/"

  add_group "Core", "lib/agents.rb"
  add_group "Agents", "lib/agents/"

  if live_llm_requested
    # Live-only runs are opt-in and may execute a small subset of specs; avoid false failures.
    minimum_coverage 0
    minimum_coverage_by_file 0
  else
    minimum_coverage 50
    minimum_coverage_by_file 40
  end
end

require_relative "../lib/agents"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Only run live LLM specs (tagged :live_llm) when explicitly enabled with credentials.
  # Prevents accidental real API calls in local/PR runs.
  unless ENV["RUN_LIVE_LLM"] && ENV["OPENAI_API_KEY"]
    config.filter_run_excluding :live_llm
  end

  # Even if someone force-includes the tag, guard at runtime to avoid config errors.
  config.before(:each, :live_llm) do
    unless ENV["RUN_LIVE_LLM"] && ENV["OPENAI_API_KEY"]
      skip "Live LLM specs require RUN_LIVE_LLM=true and OPENAI_API_KEY set"
    end
  end

  # Live specs must be able to hit the network; temporarily loosen WebMock.
  config.around(:each, :live_llm) do |example|
    if defined?(WebMock)
      previously_allowed = WebMock.net_connect_allowed?
      WebMock.allow_net_connect!
      example.run
      WebMock.disable_net_connect! unless previously_allowed
    else
      example.run
    end
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
