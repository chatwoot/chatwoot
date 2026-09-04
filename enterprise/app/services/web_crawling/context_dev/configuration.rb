module WebCrawling::ContextDev::Configuration
  INSTALLATION_CONFIG_KEY = 'CONTEXT_DEV_API_KEY'.freeze
  BASE_URL = 'https://api.context.dev/v1'.freeze

  module_function

  def configured?
    api_key.present?
  end

  def api_key
    InstallationConfig.find_by(name: INSTALLATION_CONFIG_KEY)&.value
  end
end
