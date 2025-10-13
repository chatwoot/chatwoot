class Cloudflare::CreateCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:portal!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['No hostname found'] } if @portal.custom_domain.blank?

    response = create_hostname

    return { errors: response.parsed_response['errors'] } unless response.success?

    data = response.parsed_response['result']

    if data.present?
      update_portal_ssl_settings(@portal, data)
      return { data: data }
    end

    { errors: ['Could not create hostname'] }
  end

  private

  def create_hostname
    HTTParty.post(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames",
      headers: headers,
      body: {
        hostname: @portal.custom_domain,
        ssl: {
          method: 'http',
          type: 'dv'
        }
      }.to_json
    )
  end
end
