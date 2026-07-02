module Integrations::Openai::KeyValidator
  TIMEOUT_SECONDS = 5

  def self.valid?(api_key)
    return false if api_key.blank?

    connection = Faraday.new do |f|
      f.options.timeout = TIMEOUT_SECONDS
      f.options.open_timeout = TIMEOUT_SECONDS
    end

    response = connection.get("#{api_base}/models") do |req|
      req.headers['Authorization'] = "Bearer #{api_key}"
    end

    response.status != 401
  rescue Faraday::Error => e
    Rails.logger.warn("[openai-key-validator] #{e.class}: #{e.message}")
    true
  end

  def self.api_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence || 'https://api.openai.com/'
    "#{endpoint.chomp('/')}/v1"
  end
end
