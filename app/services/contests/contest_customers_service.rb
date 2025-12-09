require 'net/http'
require 'uri'
require 'json'

module Contests
  class ContestCustomersService
    def initialize(base_url: nil, api_token: nil, dealership_id: nil)
      @base_url = GlobalConfig.get('CONTEST_API_BASE_URL')&.[]('CONTEST_API_BASE_URL')
      @api_token = GlobalConfig.get('DEALERSHIP_API_KEY')&.[]('DEALERSHIP_API_KEY')
      @dealership_id = Current.account&.dealership_id
    end

    def show(contest_id:, from_date: nil, to_date: nil)
      query = URI.encode_www_form(
        contest_id: contest_id,
        from_date: from_date,
        to_date: to_date
      )
      path = "/#{effective_dealership_id}/contest-report?#{query}"
      response = request(:get, path)
      extract_data(response)
    end

    def report(from_date:, to_date:, contest_id: nil)
      ensure_date_params!(from_date, to_date)
      query_params = {
        contest_id: contest_id,
        from_date: from_date,
        to_date: to_date
      }.compact
      query = URI.encode_www_form(query_params)
      path = "/#{effective_dealership_id}/contest-report?#{query}"
      response = request(:get, path)
      extract_data(response) || []
    end

    private

    attr_reader :base_url, :api_token, :dealership_id

    def request(method, path, payload = nil)
      ensure_api_token!
      uri = URI.parse("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = build_request(method, uri, payload)
      Rails.logger.info(
        "[Contests::ContestCustomersService] Requesting #{method.upcase} #{uri}"
      )

      response = http.request(request)
      verify_response!(response)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("[Contests::ContestCustomersService] Failed to parse response: #{e.message}")
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

      request = request_class.new(uri.request_uri)
      request['Authorization'] = "Bearer #{api_token}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = payload.to_json if payload.present?
      request
    end

    def verify_response!(response)
      return if response.is_a?(Net::HTTPSuccess)

      Rails.logger.error(
        "[Contests::ContestCustomersService] API error #{response.code}: #{response.body}"
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

    def effective_dealership_id
      dealership_id.presence ||
        raise(StandardError, 'Contest dealership id is not configured')
    end

    def ensure_date_params!(from_date, to_date)
      if from_date.blank? || to_date.blank?
        raise ArgumentError, 'from_date and to_date are required'
      end
    end
  end
end


