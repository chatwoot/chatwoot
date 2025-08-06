class Captain::Tools::BetterStackStatusTool < Captain::Tools::BasePublicTool
  description 'Check service status using Better Stack'
  param :service, type: 'string', desc: 'The service name to check status for (optional)'

  def perform(_tool_context, service: nil)
    log_tool_usage('checking_status', { service: service })

    begin
      status_data = fetch_better_stack_status(service)
      incidents_data = fetch_better_stack_incidents(service)
      format_status_response(status_data, incidents_data, service)
    rescue StandardError => e
      log_tool_usage('error', { service: service, error: e.message })
      "Error checking Better Stack status: #{e.message}"
    end
  end

  private

  def fetch_better_stack_status(service)
    # API token should be configured in environment variables or secrets
    api_token = ENV.fetch('BETTER_STACK_TOKEN')
    raise 'Better Stack API token not configured' if api_token.blank?

    # Base URL for Better Stack Status API
    base_url = 'https://uptime.betterstack.com/api/v2'

    # Endpoint depends on whether we're checking a specific service or overall status
    endpoint = if service.present?
                 "/monitors?search=#{CGI.escape(service)}"
               else
                 '/monitors'
               end

    make_api_request(base_url, endpoint, api_token)
  end

  def fetch_better_stack_incidents(service)
    api_token = ENV.fetch('BETTER_STACK_TOKEN')
    raise 'Better Stack API token not configured' if api_token.blank?

    base_url = 'https://uptime.betterstack.com/api/v2'

    # Endpoint for incidents, filter by service if provided
    endpoint = if service.present?
                 "/incidents?monitor_name=#{CGI.escape(service)}"
               else
                 '/incidents'
               end

    make_api_request(base_url, endpoint, api_token)
  end

  def make_api_request(base_url, endpoint, api_token)
    uri = URI("#{base_url}#{endpoint}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{api_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    raise "API request failed with status #{response.code}: #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def format_status_response(status_data, incidents_data, service)
    monitors = status_data['data']
    incidents = incidents_data['data']

    if monitors.empty?
      return service.present? ? "No services found matching '#{service}'" : 'No services configured in Better Stack'
    end

    result = if service.present?
               "Status for services matching '#{service}':\n\n"
             else
               "Current Better Stack Status:\n\n"
             end

    result += format_monitors(monitors)

    # Add incidents information if any exist
    if incidents.present?
      result += "\n\n🚨 Active Incidents (#{incidents.size}):\n\n"
      result += format_incidents(incidents)
    end

    result
  end

  def format_monitors(monitors)
    monitors.map do |monitor|
      attributes = monitor['attributes']
      status = attributes['status']
      status_emoji = case status
                     when 'up'
                       '✅'
                     when 'down'
                       '❌'
                     else
                       '⚠️'
                     end

      last_check = begin
        Time.zone.parse(attributes['last_check_at'])
      rescue StandardError
        'Unknown'
      end
      last_check_formatted = last_check.is_a?(Time) ? last_check.strftime('%Y-%m-%d %H:%M:%S') : last_check

      "#{status_emoji} #{attributes['url']}: #{status.upcase} (Last checked: #{last_check_formatted})"
    end.join("\n")
  end

  def format_incidents(incidents)
    incidents.map do |incident|
      attributes = incident['attributes']
      # Format start time
      started_at = begin
        Time.zone.parse(attributes['started_at'])
      rescue StandardError
        'Unknown'
      end
      started_at_formatted = started_at.is_a?(Time) ? started_at.strftime('%Y-%m-%d %H:%M:%S') : started_at

      # Get monitor name and incident status
      status = attributes['status'] || 'unknown'

      # Format incident details
      "🔴 [#{status.upcase}] #{attributes['name']} - #{attributes['title']}\n   " \
        "Started: #{started_at_formatted}\n   " \
        "#{attributes['url'] ? "Details: #{attributes['url']}" : ''}"
    end.join("\n\n")
  end
end
