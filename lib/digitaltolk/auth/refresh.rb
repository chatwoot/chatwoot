class Digitaltolk::Auth::Refresh
  API_URL = 'https://auth.digitaltolk.com/api/v1/oauth/token'.freeze

  def initialize(refresh_token, client_id: nil, client_secret: nil, tenant: nil)
    @client_id = client_id || ENV.fetch('DT_CLIENT_ID', nil)
    @client_secret = client_secret || ENV.fetch('DT_CLIENT_SECRET', nil)
    @tenant = tenant || ENV.fetch('DT_TENANT_UUID', nil)
    @refresh_token = refresh_token
  end

  def perform
    generate_token
  end

  private

  def generate_token
    response = HTTParty.post(
      API_URL,
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    raise "Failed to generate token: #{response.code}" unless response.success?

    JSON.parse(response.body)
  end

  def payload
    {
      grant_type: 'refresh_token',
      client_id: @client_id,
      tenant: @tenant,
      refresh_token: @refresh_token
    }
  end
end
