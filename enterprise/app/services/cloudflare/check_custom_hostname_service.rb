class Cloudflare::CheckCustomHostnameService < Cloudflare::BaseCloudflareZoneService
  pattr_initialize [:portal!]

  def perform
    return { errors: ['Cloudflare API token or zone ID not found'] } if api_token.blank? || zone_id.blank?
    return { errors: ['No custom domain found'] } if @portal.custom_domain.blank?

    response = fetch_hostnames(@portal.custom_domain)

    return { errors: response.parsed_response['errors'] } unless response.success?

    data = response.parsed_response['result']
    live_hostname = find_live_hostname(data)

    if live_hostname.present?
      update_portal_ssl_settings(@portal, live_hostname)
      return { data: data }
    end

    { errors: ['Hostname is missing in Cloudflare'] }
  end

  private

  def find_live_hostname(data)
    Array(data).find { |hostname| hostname['status'] != 'deleted' }
  end
end
