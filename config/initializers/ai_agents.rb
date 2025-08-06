# frozen_string_literal: true

require 'agents'

Rails.application.config.after_initialize do
  api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value || 'gpt-4.1-mini'
  api_base = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value || 'https://api.openai.com'

  puts "api_base: #{api_base}"

  if api_key.present?
    Agents.configure do |config|
      config.openai_api_key = api_key
      config.openai_api_base = api_base if api_base.present?
      config.default_model = model
      config.debug = false
    end
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
end
