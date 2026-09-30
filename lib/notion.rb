class Notion
  BASE_URL = 'https://api.notion.com'.freeze
  NOTION_VERSION = '2022-06-28'.freeze

  def initialize(access_token)
    raise ArgumentError, 'Missing Credentials' if access_token.blank?
    @access_token = access_token
  end

  def create_page(parent_id, title, children, parent_type: :page_id)
    payload = {
      parent: { parent_type.to_sym => parent_id },
      properties: { title: { title: [{ text: { content: title } }] } },
      children: children
    }

    response = post('/v1/pages', payload)
    process_response(response)
  end

  private

  def post(path, payload)
    HTTParty.post(
      "#{BASE_URL}#{path}",
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Notion-Version' => NOTION_VERSION,
        'Content-Type' => 'application/json'
      },
      body: payload.to_json
    )
  end

  def process_response(response)
    return response.with_indifferent_access if response.success?

    raise StandardError, "Notion API error: #{response.code} #{response.body}"
  end
end