require 'openai'

class Digitaltolk::Openai::Base
  API_BASE_URL = ENV.fetch('DT_LLM_HUB_URL', 'https://api-gateway-stg.digitaltolk.net')
  API_VERSION = ENV.fetch('DT_LLM_HUB_API_VERSION', 'api/v3/llm-hub')
  DT_ADMIN_USERNAME = ENV.fetch('DT_ADMIN_USERNAME', nil)

  def initialize
    initialize_client
  end

  def initialize_client
    @client = OpenAI::Client.new(
      uri_base: API_BASE_URL,
      access_token: access_token,
      log_errors: Rails.env.development?,
      api_version: API_VERSION
    )
  end

  def perform
    raise NotImplementedError
  end

  private

  attr_reader :client

  def access_token
    @access_token ||= UserAuth.token_by_email(DT_ADMIN_USERNAME)
  end

  def system_prompt
    raise NotImplementedError
  end

  def user_prompt
    raise NotImplementedError
  end

  def call_openai
    client.chat(
      parameters: {
        model: 'openai/gpt4o_mini',
        messages: messages,
        response_format: { type: 'json_object' }
      }
    )
  end

  def parse_response(response)
    return {} if response.blank?

    if response.is_a?(Hash)
      response
    else
      JSON.parse(response)
    end
  end
end
