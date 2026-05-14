class Integrations::Remnawave::ApiClient
  attr_reader :base_url, :api_token

  def initialize(base_url:, api_token:)
    @base_url = base_url.chomp('/')
    @api_token = api_token
  end

  def user_by_telegram_id(telegram_id)
    get("/api/users/by-telegram-id/#{telegram_id}")
  end

  def user_by_uuid(uuid)
    get("/api/users/#{uuid}")
  end

  def enable_user(uuid)
    post("/api/users/#{uuid}/actions/enable")
  end

  def disable_user(uuid)
    post("/api/users/#{uuid}/actions/disable")
  end

  def reset_traffic(uuid)
    post("/api/users/#{uuid}/actions/reset-traffic")
  end

  private

  def get(path)
    response = HTTParty.get(
      "#{base_url}#{path}",
      headers: auth_headers,
      timeout: 10
    )
    handle_response(response)
  end

  def post(path, body = nil)
    options = { headers: auth_headers, timeout: 10 }
    options[:body] = body.to_json if body
    options[:headers]['Content-Type'] = 'application/json' if body

    response = HTTParty.post("#{base_url}#{path}", **options)
    handle_response(response)
  end

  def auth_headers
    { 'Authorization' => "Bearer #{api_token}" }
  end

  def handle_response(response)
    case response.code
    when 200, 201
      response.parsed_response
    when 404
      nil
    else
      raise "Remnawave API error: #{response.code} - #{response.body}"
    end
  end
end
