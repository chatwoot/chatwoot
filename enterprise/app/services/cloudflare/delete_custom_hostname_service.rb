class Cloudflare::DeleteCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:hostname_id!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['Hostname ID is required'] } if @hostname_id.blank?

    response = HTTParty.delete(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames/#{@hostname_id}",
      headers: headers
    )

    return { errors: response.parsed_response['errors'] } unless response.success?

    { success: true }
  end
end
