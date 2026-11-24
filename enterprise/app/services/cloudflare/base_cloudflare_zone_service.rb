class Cloudflare::BaseCloudflareZoneService
  BASE_URI = 'https://api.cloudflare.com/client/v4'.freeze

  private

  def headers
    {
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/json'
    }
  end

  def fetch_hostnames(hostname)
    HTTParty.get("#{BASE_URI}/zones/#{zone_id}/custom_hostnames?hostname=#{hostname}", headers: headers)
  end

  def api_token
    InstallationConfig.find_by(name: 'CLOUDFLARE_API_KEY')&.value
  end

  def zone_id
    InstallationConfig.find_by(name: 'CLOUDFLARE_ZONE_ID')&.value
  end

  def update_portal_ssl_settings(portal, data)
    verification_record = data['ownership_verification_http']
    ssl_record = data['ssl']
    verification_errors = data['verification_errors']&.first || ''

    # Start with existing settings to preserve verification data if it exists
    ssl_settings = portal.ssl_settings || {}

    # Only update verification fields if they exist in the response (during initial setup)
    if verification_record.present?
      ssl_settings['cf_verification_id'] = verification_record['http_url'].split('/').last
      ssl_settings['cf_verification_body'] = verification_record['http_body']
    end

    # Always update SSL status and errors from current response
    ssl_settings['cf_status'] = ssl_record&.dig('status')
    ssl_settings['cf_verification_errors'] = verification_errors

    portal.update(ssl_settings: ssl_settings)
  end
end
