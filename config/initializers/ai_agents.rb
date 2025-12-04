# frozen_string_literal: true

require 'agents'

Rails.application.config.after_initialize do
  api_key = InstallationConfig.find_by(name: 'LEGACY_OPENAI_AGENTS_API_KEY')&.value
  model = Integrations::OpenaiConstants.model
  api_endpoint = Integrations::OpenaiConstants.endpoint

  if api_key.present?
    Agents.configure do |config|
      config.openai_api_key = api_key
      if api_endpoint.present?
        api_base = "#{api_endpoint.chomp('/')}/v1"
        config.openai_api_base = api_base
      end
      config.default_model = model
      config.debug = false
    end
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
end
