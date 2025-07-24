class Cloudflare::BaseCloudflareZoneService
  BASE_URI = 'https://api.cloudflare.com/client/v4'.freeze

  private

  def headers
    {
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/json'
    }
  end

  def api_token
    InstallationConfig.find_by(name: 'CLOUDFLARE_API_KEY')&.value
  end

  def zone_id
    InstallationConfig.find_by(name: 'CLOUDFLARE_ZONE_ID')&.value
  end
end
