class Cloudflare::CheckCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:portal!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['No custom domain found'] } if @portal.custom_domain.blank?

    response = HTTParty.get(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames?hostname=#{@portal.custom_domain}", headers: headers
    )

    return { errors: response.parsed_response['errors'] } unless response.success?

    data = response.parsed_response['result']

    if data.present?
      update_portal_ssl_settings(@portal, data.first)
      return { data: data }
    end

    { errors: ['Hostname is missing in Cloudflare'] }
  end
end
