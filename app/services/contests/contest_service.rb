require 'net/http'
require 'uri'
require 'json'

module Contests
  class ContestService

    def initialize(dealership_id: nil, base_url: nil, api_token: nil)
      @base_url = GlobalConfig.get('CONTEST_API_BASE_URL')&.[]('CONTEST_API_BASE_URL')
      @api_token = GlobalConfig.get('DEALERSHIP_API_KEY')&.[]('DEALERSHIP_API_KEY')
      
      @dealership_id = Current.account.dealership_id

    end

    def list
      response = request(:get, resource_path)
      extract_data(response) || []
    end

    def create(payload)
      response = request(:post, resource_path, payload)
      extract_data(response)
    end

    def update(contest_id, payload)
      response = request(:put, "#{resource_path}/#{contest_id}", payload)
      extract_data(response)
    end

    def delete(contest_id)
      request(:delete, "#{resource_path}/#{contest_id}")
      true
    end

    private

    attr_reader :base_url, :dealership_id, :api_token

    def resource_path
      "/#{dealership_id}/contest"
    end

    def request(method, path, payload = nil)
      ensure_api_token!
      
      # Ensure base_url is valid and has a scheme
      full_url = "#{base_url}#{path}"
      unless full_url.match?(/\Ahttps?:\/\//)
        raise StandardError, "Invalid base URL: #{base_url}. Must include http:// or https://"
      end
      
      uri = URI.parse(full_url)
      
      # Ensure we have an HTTP/HTTPS URI
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise StandardError, "Invalid URL scheme. Must be http:// or https://"
      end
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = build_request(method, uri, payload)

      Rails.logger.info(
        "[Contests::ContestService] Requesting #{method.upcase} #{uri} payload=#{payload.present?}"
      )

      response = http.request(request)
      verify_response!(response)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("[Contests::ContestService] Failed to parse response: #{e.message}")
      raise
    end

    def build_request(method, uri, payload)
      request_class =
        case method
        when :get then Net::HTTP::Get
        when :post then Net::HTTP::Post
        when :put then Net::HTTP::Put
        when :delete then Net::HTTP::Delete
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end

      # Use request_uri if available (HTTP/HTTPS), otherwise construct path manually
      request_path = if uri.respond_to?(:request_uri)
                       uri.request_uri
                     else
                       path = uri.path || '/'
                       path += "?#{uri.query}" if uri.query
                       path
                     end

      request = request_class.new(request_path)
      request['Authorization'] = "Bearer #{api_token}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = payload.to_json if payload.present?
      request
    end

    def verify_response!(response)
      return if response.is_a?(Net::HTTPSuccess)

      Rails.logger.error(
        "[Contests::ContestService] API error #{response.code}: #{response.body}"
      )
      raise StandardError, "Contest API error: #{response.code}"
    end

    def extract_data(response_body)
      response_body.dig('body', 'data')
    end

    def ensure_api_token!
      return if api_token.present?

      raise StandardError, 'Contest API token is not configured'
    end
  end
end

