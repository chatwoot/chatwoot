# frozen_string_literal: true

module Crm
  class BaseClient
    class ApiError < StandardError; end
    class TokenExpiredError < ApiError; end

    attr_reader :hook

    def initialize(hook)
      @hook = hook
      @credentials = hook.credentials
      @retry_attempted = false
    end

    # Método principal para hacer requests al CRM
    def request(method, path, options = {})
      # Refrescar token antes de cada request si es necesario
      ensure_valid_token!

      # Hacer request con token válido
      response = http_client.public_send(
        method,
        build_url(path),
        build_options(options)
      )

      handle_response(response)
    rescue TokenExpiredError => e
      # Si aún así el token expiró (edge case), refrescar y reintentar una vez
      if @retry_attempted
        Rails.logger.error "Token still expired after refresh attempt: #{e.message}"
        raise
      end

      Rails.logger.info "Token expired during request, refreshing and retrying..."
      @hook.refresh_access_token!
      @credentials = @hook.reload.credentials
      @retry_attempted = true
      retry
    end

    private

    def ensure_valid_token!
      return unless @hook.token_expired?

      Rails.logger.info "Token expired, refreshing before request..."
      @hook.refresh_token_if_needed
      @credentials = @hook.reload.credentials # Recargar credenciales actualizadas
    end

    def build_options(options)
      {
        headers: default_headers.merge(options[:headers] || {}),
        body: options[:body],
        query: options[:query]
      }.compact
    end

    def default_headers
      {
        'Authorization' => "#{@credentials['token_type']} #{@credentials['access_token']}",
        'Content-Type' => 'application/json'
      }
    end

    def build_url(path)
      "#{base_url}#{path}"
    end

    # Subclases deben implementar este método
    def base_url
      raise NotImplementedError, 'Subclass must implement base_url'
    end

    def http_client
      HTTParty
    end

    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      when 401
        raise TokenExpiredError, "Token expired or invalid: #{response.body}"
      when 400..499
        raise ApiError, "Client error: #{response.code} - #{response.body}"
      when 500..599
        raise ApiError, "Server error: #{response.code} - #{response.body}"
      else
        raise ApiError, "Unexpected response: #{response.code} - #{response.body}"
      end
    end
  end
end
