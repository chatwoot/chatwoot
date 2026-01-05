# frozen_string_literal: true

# Configure RubyLLM for Aloo AI Agent
# RubyLLM is a multi-provider LLM abstraction gem
# See: https://rubyllm.com

RubyLLM.configure do |config|
  # API Keys from environment
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)

  # Request configuration
  config.request_timeout = 120 # seconds

  # Logging (use Rails logger in development)
  config.logger = Rails.logger if Rails.env.development?
end
