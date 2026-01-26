class Notion::ApiClient
  BASE_URL = 'https://api.notion.com'.freeze
  NOTION_VERSION = '2025-09-03'.freeze

  def initialize(access_token)
    @access_token = access_token
  end

  def get(path, params = {})
    request(:get, path, params: params)
  end

  def post(path, body = {})
    request(:post, path, body: body)
  end

  private

  def request(method, path, params: {}, body: {})
    url = "#{BASE_URL}#{path}"

    options = {
      headers: headers,
      query: params,
      timeout: 30
    }

    options[:body] = body.to_json if body.present?

    response = HTTParty.send(method, url, options)

    unless response.success?
      Rails.logger.error "Notion API Error: #{response.code} - #{response.body}"
      raise CustomExceptions::Notion::ApiError, extract_error_message(response)
    end

    response.parsed_response
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error "Notion API Request Failed: #{e.message}"
    raise CustomExceptions::Notion::ApiError, "Failed to connect to Notion API: #{e.message}"
  end

  def headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Notion-Version' => NOTION_VERSION,
      'Content-Type' => 'application/json'
    }
  end

  def extract_error_message(response)
    parsed = response.parsed_response
    return parsed['message'] if parsed.is_a?(Hash) && parsed['message']

    "Notion API returned status #{response.code}"
  rescue StandardError
    "Notion API returned status #{response.code}"
  end
end
