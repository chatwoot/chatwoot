class Notion
  BASE_URL = 'https://api.notion.com/v1'.freeze

  def initialize(access_token)
    @access_token = access_token
    raise ArgumentError, 'Missing Credentials' if access_token.blank?
  end

  def search(query = '', sort = nil)
    payload = { query: query }
    payload[:sort] = sort if sort.present?

    response = post('search', payload)
    process_response(response)
  end

  def page(page_id)
    raise ArgumentError, 'Missing page id' if page_id.blank?

    response = get("pages/#{page_id}")
    process_response(response)
  end

  def page_blocks(page_id)
    raise ArgumentError, 'Missing page id' if page_id.blank?

    response = get("blocks/#{page_id}/children")
    process_response(response)
  end

  private

  def get(path)
    HTTParty.get(
      "#{BASE_URL}/#{path}",
      headers: default_headers
    )
  end

  def post(path, payload)
    HTTParty.post(
      "#{BASE_URL}/#{path}",
      headers: default_headers,
      body: payload.to_json
    )
  end

  def default_headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Notion-Version' => GlobalConfigService.load('NOTION_VERSION', '2022-06-28'),
      'Content-Type' => 'application/json'
    }
  end

  def process_response(response)
    return response.parsed_response.with_indifferent_access if response.success?

    { error: response.parsed_response, error_code: response.code }
  end
end