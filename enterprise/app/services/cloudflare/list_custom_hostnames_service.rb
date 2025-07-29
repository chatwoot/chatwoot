class Cloudflare::ListCustomHostnamesService < Cloudflare::BaseCloudflareZoneService
  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?

    response = HTTParty.get(
      "#{BASE_URI}/zones/#{zone_id}/custom_hostnames",
      headers: headers
    )

    return { errors: response.parsed_response['errors'] } unless response.success?

    { data: response.parsed_response['result'] }
  end
end
