class Cloudflare::CreateCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:portal!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['No hostname found'] } if @portal.custom_domain.blank?

    response = create_hostname
    if duplicate_hostname?(response)
      remove_deleted_hostnames
      response = create_hostname
    end

    return { errors: response.parsed_response['errors'] } unless response.success?

    data = response.parsed_response['result']

    if data.present?
      update_portal_ssl_settings(@portal, data)
      return { data: data }
    end

    { errors: ['Could not create hostname'] }
  end

  private

  DUPLICATE_HOSTNAME_ERROR_CODE = 1406

  def duplicate_hostname?(response)
    Array(response.parsed_response&.dig('errors')).any? { |error| error['code'] == DUPLICATE_HOSTNAME_ERROR_CODE }
  end

  def remove_deleted_hostnames
    response = fetch_hostnames(@portal.custom_domain)
    return unless response.success?

    Array(response.parsed_response['result']).select { |hostname| hostname['status'] == 'deleted' }.each do |hostname|
      HTTParty.delete("#{BASE_URI}/zones/#{zone_id}/custom_hostnames/#{hostname['id']}", headers: headers)
    end
  end

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
