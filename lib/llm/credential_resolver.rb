class Llm::CredentialResolver
  def initialize(provider: Llm::Config.default_provider, openai_hook: nil)
    @provider = provider.to_s
    @openai_hook = openai_hook
  end

  def resolve
    hook_llm_credential || system_llm_credential
  end

  private

  attr_reader :provider, :openai_hook

  def hook_llm_credential
    return unless provider == Llm::Config::DEFAULT_PROVIDER

    key = openai_hook&.settings&.dig('api_key').presence
    { api_key: key, source: :hook } if key
  end

  def system_llm_credential
    return { api_key: system_api_key, auth_token: system_auth_token, source: :system } if system_api_key.present? || azure_auth_token_configured?
    return { api_key: nil, source: :system } if Llm::Config.api_base_only_provider_configured?(provider: provider)
  end

  def system_api_key
    @system_api_key ||= InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  def system_auth_token
    @system_auth_token ||= InstallationConfig.find_by(name: 'CAPTAIN_AZURE_AI_AUTH_TOKEN')&.value
  end

  def azure_auth_token_configured?
    provider == Llm::Config::AZURE_PROVIDER && system_auth_token.present?
  end
end
