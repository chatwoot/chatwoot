# frozen_string_literal: true

module Zerodb
  # Base service class for all ZeroDB API interactions
  # Provides common HTTP client configuration, authentication, error handling,
  # and retry logic with rate limiting support for all ZeroDB API services
  class BaseService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    # Rate limiting and retry configuration
    MAX_RETRIES = 3
    RETRY_DELAY = 1 # seconds
    RATE_LIMIT_ERROR_CODES = [429].freeze
    TIMEOUT = 30 # seconds

    # Custom error classes for better error handling
    class ZeroDBError < StandardError; end
    class AuthenticationError < ZeroDBError; end
    class RateLimitError < ZeroDBError; end
    class ValidationError < ZeroDBError; end
    class NetworkError < ZeroDBError; end
    class ConfigurationError < ZeroDBError; end

    # Initialize with optional project-specific configuration
    def initialize
      @project_id = ENV.fetch('ZERODB_PROJECT_ID', nil)
      @api_key = ENV.fetch('ZERODB_API_KEY', nil)
      validate_credentials!
    end

    private

    # Standard headers for all ZeroDB API requests
    # @return [Hash] Headers including authentication and content type
    def headers
      {
        'X-API-Key' => @api_key,
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    # Validate that required credentials are present
    # @raise [ConfigurationError] if credentials are missing
    def validate_credentials!
      raise ConfigurationError, 'ZERODB_API_KEY environment variable is not set' if @api_key.blank?
      raise ConfigurationError, 'ZERODB_PROJECT_ID environment variable is not set' if @project_id.blank?
    end

    # Build full API endpoint path with project ID
    # @param path [String] API endpoint path
    # @return [String] Complete path with project ID prefix
    def api_path(endpoint)
      "/#{@project_id}#{endpoint}"
    end

    # Make HTTP request with retry logic and comprehensive error handling
    # @param method [Symbol] HTTP method (:get, :post, :put, :delete, :patch)
    # @param path [String] API endpoint path
    # @param options [Hash] HTTParty options (body, query, etc.)
    # @return [Hash] Parsed response body
    # @raise [NetworkError, RateLimitError, AuthenticationError, ValidationError, ZeroDBError]
    def make_request(method, path, options = {})
      retries = 0
      start_time = Time.current

      begin
        log_request(method, path, options)

        response = self.class.send(
          method,
          path,
          options.merge(
            headers: headers,
            timeout: TIMEOUT
          )
        )

        duration = ((Time.current - start_time) * 1000).round(2)
        log_response(response, duration)

        handle_response(response)
      rescue HTTParty::Error, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, SocketError => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn("[ZeroDB] Request failed, retrying (#{retries}/#{MAX_RETRIES}): #{e.message}")
          sleep(RETRY_DELAY * retries) # Exponential backoff
          retry
        else
          raise NetworkError, "Failed to connect to ZeroDB API after #{MAX_RETRIES} retries: #{e.message}"
        end
      end
    end

    # Handle API response and raise appropriate errors based on status code
    # @param response [HTTParty::Response] API response
    # @return [Hash] Parsed response body
    # @raise [AuthenticationError, RateLimitError, ValidationError, ZeroDBError]
    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      when 401, 403
        error_message = parse_error_message(response)
        Rails.logger.error("[ZeroDB] Authentication failed: #{error_message}")
        raise AuthenticationError, "Authentication failed: #{error_message}"
      when 429
        error_message = parse_error_message(response)
        Rails.logger.warn("[ZeroDB] Rate limit exceeded: #{error_message}")
        raise RateLimitError, "Rate limit exceeded. Please try again later: #{error_message}"
      when 400, 422
        error_message = parse_error_message(response)
        Rails.logger.error("[ZeroDB] Validation error: #{error_message}")
        raise ValidationError, "Validation error: #{error_message}"
      when 404
        error_message = parse_error_message(response)
        Rails.logger.error("[ZeroDB] Resource not found: #{error_message}")
        raise ZeroDBError, "Resource not found: #{error_message}"
      when 500..599
        error_message = parse_error_message(response)
        Rails.logger.error("[ZeroDB] Server error: #{error_message}")
        raise ZeroDBError, "ZeroDB server error: #{error_message}"
      else
        error_message = parse_error_message(response)
        Rails.logger.error("[ZeroDB] Unexpected error (#{response.code}): #{error_message}")
        raise ZeroDBError, "Unexpected error (#{response.code}): #{error_message}"
      end
    rescue JSON::ParserError => e
      Rails.logger.error("[ZeroDB] Invalid JSON response: #{e.message}")
      raise ZeroDBError, "Invalid JSON response from API: #{e.message}"
    end

    # Parse error message from API response
    # @param response [HTTParty::Response] API response
    # @return [String] Error message
    def parse_error_message(response)
      return response.message unless response.body

      parsed = JSON.parse(response.body)
      parsed['error'] || parsed['message'] || parsed['detail'] || response.message
    rescue JSON::ParserError
      response.message
    end

    # Log API request for debugging and monitoring
    # @param method [Symbol] HTTP method
    # @param path [String] API endpoint path
    # @param options [Hash] Request options
    def log_request(method, path, options = {})
      Rails.logger.info("[ZeroDB] #{method.upcase} #{path}")
      Rails.logger.debug("[ZeroDB] Request options: #{sanitize_log_data(options)}")
    end

    # Log API response for debugging and monitoring
    # @param response [HTTParty::Response] API response
    # @param duration [Float] Request duration in milliseconds
    def log_response(response, duration = nil)
      status = response.code
      log_level = status >= 400 ? :error : :info

      Rails.logger.send(log_level, "[ZeroDB] Response: #{status} (#{duration}ms)")
      Rails.logger.debug("[ZeroDB] Response body: #{sanitize_log_data(response.parsed_response)}")
    end

    # Sanitize sensitive data from logs
    # @param data [Hash] Data to sanitize
    # @return [Hash] Sanitized data
    def sanitize_log_data(data)
      return data unless data.is_a?(Hash)

      data.deep_dup.tap do |sanitized|
        # Remove API keys and sensitive data from logs
        sanitized['headers']&.delete('X-API-Key')
        sanitized.delete('api_key')
        sanitized.delete('password')
      end
    end
  end
end
