# frozen_string_literal: true

class Twitty::Facade
  include Twitty::Constants
  include Twitty::Payload

  def initialize
    yield(config) if block_given?
  end

  API_CONFIG.each do |action, _config|
    define_method action do |data = {}|
      define_actions(action, data)
    end
  end

  def generate_crc(crc_token)
    hash = OpenSSL::HMAC.digest('sha256', config.consumer_secret, crc_token)
    Base64.encode64(hash).strip!
  end

  def override_client_tokens(access_token, access_token_secret)
    config.access_token = access_token
    config.access_token_secret = access_token_secret
  end

  private

  def define_actions(action, data)
    validate_params(action, data)
    response = send_request(api_url(action, data), api_method(action),
                            api_params(action, data))
    Twitty::Response.new(response)
  end

  def validate_params(action, data)
    missing_params = (API_CONFIG[action][:required_params] - data.keys.map(&:to_sym))
    raise Twitty::Errors::MissingParams, missing_params.join(',') unless missing_params.empty?
  end

  def api_params(action, data)
    build_payload(action, data)
  end

  def send_request(url, type, params)
    Twitty::Request.new(url: url, type: type, payload: params, config: config).execute
  end

  def config
    @config ||= Twitty::Config.new
  end

  def api_url(action, data)
    url_params = data.merge(env: config.environment).map { |k, v| [k, CGI.escape(v)] }.to_h
    "#{config.base_url}#{API_CONFIG[action][:endpoint]}" % url_params
  end

  def api_method(action)
    API_CONFIG[action][:method]
  end
end
