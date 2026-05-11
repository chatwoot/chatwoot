class Notion::ApiClient
  BASE_URL = 'https://api.notion.com/v1'.freeze

  def initialize(access_token)
    raise ArgumentError, 'Missing Credentials' if access_token.blank?

    @access_token = access_token
  end

  def get(path)
    process_response(HTTParty.get(url_for(path), headers: headers))
  end

  def post(path, body = {})
    process_response(HTTParty.post(url_for(path), headers: headers, body: body.to_json))
  end

  def patch(path, body = {})
    process_response(HTTParty.patch(url_for(path), headers: headers, body: body.to_json))
  end

  private

  def url_for(path)
    "#{BASE_URL}/#{path.to_s.sub(%r{\A/+}, '')}"
  end

  def headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json',
      'Notion-Version' => GlobalConfigService.load('NOTION_VERSION', '2026-03-11')
    }
  end

  def process_response(response)
    return response.parsed_response.with_indifferent_access if response.success?

    { error: response.parsed_response, error_code: response.code }
  end
end
