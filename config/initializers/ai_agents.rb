# frozen_string_literal: true

# Load AI Agents SDK
begin
  require 'agents'
rescue LoadError => e
  Rails.logger.warn "AI Agents SDK not available: #{e.message}"
end

# Configure AI Agents SDK
if defined?(Agents)
  Rails.application.config.after_initialize do
    api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value || 'gpt-4o-mini'

    if api_key.present?
      Agents.configure do |config|
        config.openai_api_key = api_key
        config.default_model = model
        config.debug = false
      end
    end
  rescue StandardError => e
    Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
  end
end
