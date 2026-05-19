# frozen_string_literal: true

require 'agents'

Rails.application.config.after_initialize do
  api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || LlmConstants::DEFAULT_MODEL
  provider = Llm::Config.default_provider
  api_base = Llm::Config.api_base_for(provider: provider)

  if api_key.present? || api_base.present?
    Agents.configure do |config|
      Llm::Config.configure_provider(config, provider: provider, api_key: api_key, api_base: api_base)
      config.default_model = model
      config.debug = false
    end

    Llm::Config.reset!
    Llm::Config.initialize!
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
end
