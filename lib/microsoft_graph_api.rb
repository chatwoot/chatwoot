# Simple HTTPS API helper class for interacting with MS Graph.
# Uses the standard ruby HTTP library for interacting with the API.

require 'uri'
require 'net/http'

class MicrosoftGraphApi
  API_VERSION = 'v1.0'.freeze
  API_PORT = 443
  API_URL = "https://graph.microsoft.com/#{API_VERSION}".freeze

  def initialize(token)
    @token = token
  end

  # Simple get request to the endpoint
  #
  # 'queries' are the get variables after the main url
  # eg. foo/bar?query=myquery
  def get_from_api(endpoint, headers = {}, query = {})
    uri = endpoint_to_uri(endpoint, query)
    https = setup_https(uri.host)
    request = Net::HTTP::Get.new(uri.request_uri)

    # Assign each header to the request
    headers.each { |key, value| request[key.to_s] = value.to_s }
    request['Authorization'] = "Bearer #{@token}"

    https.request(request)
  end

  # Simple post request to the endpoint
  def post_to_api(endpoint, headers = {}, body = '')
    uri = endpoint_to_uri(endpoint)
    https = setup_https(uri.host)
    request = Net::HTTP::Post.new(uri.path)

    # Assign each header to the request
    headers.each { |key, value| request[key.to_s] = value.to_s }
    request['Authorization'] = "Bearer #{@token}"

    request.body = body
    https.request(request)
  end

  private

  def setup_https(host, _port = API_PORT)
    https = Net::HTTP.new(host, API_PORT)
    https.use_ssl = true
    https
  end

  def endpoint_to_uri(endpoint, query = {})
    endpoint.delete_prefix('/')
    uri = URI("#{API_URL}/#{endpoint}")
    return uri if query.empty?

    uri.query = URI.encode_www_form(query)
    uri
  end
end
