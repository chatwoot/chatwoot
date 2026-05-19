# frozen_string_literal: true

require 'agents'

Rails.application.config.after_initialize do
  api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || LlmConstants::DEFAULT_MODEL
  provider = Llm::Config.default_provider
  api_base = Llm::Config.api_base_for(provider: provider)

  apply_provider_config = lambda do |config|
    provider_options = RubyLLM::Provider.providers[provider.to_sym]&.configuration_options || []
    api_key_option = :"#{provider}_api_key"
    api_base_option = :"#{provider}_api_base"

    if api_key.present? && provider_options.include?(api_key_option) && config.respond_to?(api_key_option)
      config.public_send("#{api_key_option}=", api_key)
    end

    if api_base.present? && provider_options.include?(api_base_option) && config.respond_to?(api_base_option)
      config.public_send("#{api_base_option}=", api_base)
    end
  end

  if api_key.present? || api_base.present?
    Agents.configure do |config|
      apply_provider_config.call(config)
      config.default_model = model
      config.debug = false
    end

    Llm::Config.reset!
    Llm::Config.initialize!
  end
rescue StandardError => e
  Rails.logger.error "Failed to configure AI Agents SDK: #{e.message}"
end
