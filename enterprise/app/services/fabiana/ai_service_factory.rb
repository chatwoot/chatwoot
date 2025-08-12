class Fabiana::AiServiceFactory
  class UnsupportedProviderError < StandardError; end
  class ConfigurationError < StandardError; end

  PROVIDER_SERVICES = {
    'openai' => 'Fabiana::OpenaiService',
    'chatgpt' => 'Fabiana::ChatgptService',
    'groq' => 'Fabiana::GroqService'
  }.freeze

  def self.create_service(provider = nil)
    provider ||= get_configured_provider
    
    unless PROVIDER_SERVICES.key?(provider)
      raise UnsupportedProviderError, "Unsupported AI provider: #{provider}"
    end

    service_class = PROVIDER_SERVICES[provider].constantize
    service_class.new
  rescue NameError => e
    raise ConfigurationError, "Failed to load service for provider #{provider}: #{e.message}"
  end

  def self.get_configured_provider
    provider = InstallationConfig.find_by(name: 'FABIANA_AI_PROVIDER')&.value
    provider.presence || 'openai'
  end

  def self.available_providers
    PROVIDER_SERVICES.keys
  end

  def self.provider_configured?(provider)
    case provider
    when 'openai'
      openai_configured?
    when 'chatgpt'
      chatgpt_configured?
    when 'groq'
      groq_configured?
    else
      false
    end
  end

  def self.get_provider_status
    available_providers.map do |provider|
      {
        name: provider,
        configured: provider_configured?(provider),
        active: provider == get_configured_provider
      }
    end
  end

  private

  def self.openai_configured?
    InstallationConfig.find_by(name: 'FABIANA_OPEN_AI_API_KEY')&.value.present?
  end

  def self.chatgpt_configured?
    InstallationConfig.find_by(name: 'FABIANA_CHATGPT_API_KEY')&.value.present?
  end

  def self.groq_configured?
    InstallationConfig.find_by(name: 'FABIANA_GROQ_API_KEY')&.value.present?
  end
end
