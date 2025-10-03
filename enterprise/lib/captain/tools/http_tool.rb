require 'agents'

class Captain::Tools::HttpTool < Agents::Tool
  def initialize(assistant, custom_tool)
    @assistant = assistant
    @custom_tool = custom_tool
    super()
  end

  def active?
    @custom_tool.enabled?
  end

  def perform(_tool_context, **params)
    url = @custom_tool.build_request_url(params)
    body = @custom_tool.build_request_body(params)

    response = execute_http_request(url, body)
    @custom_tool.format_response(response.body)
  rescue StandardError => e
    Rails.logger.error("HttpTool execution error for #{@custom_tool.slug}: #{e.class} - #{e.message}")
    'An error occurred while executing the request'
  end

  private

  def execute_http_request(url, body)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 30
    http.open_timeout = 10

    request = build_http_request(uri, body)
    apply_authentication(request)

    response = http.request(request)

    raise "HTTP request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def build_http_request(uri, body)
    if @custom_tool.http_method == 'POST'
      request = Net::HTTP::Post.new(uri.request_uri)
      if body
        request.body = body
        request['Content-Type'] = 'application/json'
      end
    else
      request = Net::HTTP::Get.new(uri.request_uri)
    end
    request
  end

  def apply_authentication(request)
    headers = @custom_tool.build_auth_headers
    headers.each { |key, value| request[key] = value }

    credentials = @custom_tool.build_basic_auth_credentials
    request.basic_auth(*credentials) if credentials
  end
end
