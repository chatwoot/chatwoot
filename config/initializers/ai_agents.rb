# frozen_string_literal: true

require 'agents'

Rails.application.config.after_initialize do
  api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || LlmConstants::DEFAULT_MODEL
  api_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value || LlmConstants::OPENAI_API_ENDPOINT

  Agents.configure do |config|
    config.openai_api_key = api_key if api_key.present?
    if api_key.present? && api_endpoint.present?
      api_base = "#{api_endpoint.chomp('/')}/v1"
      config.openai_api_base = api_base
    end
    config.default_model = model
    config.openai_protocol = :chat_completions
    config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
    config.debug = false
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
end
