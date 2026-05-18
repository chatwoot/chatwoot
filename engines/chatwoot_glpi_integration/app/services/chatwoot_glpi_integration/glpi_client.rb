require 'faraday'
require 'faraday/retry'

module ChatwootGlpiIntegration
  # Thin HTTP client for GLPI 11.x REST API using OAuth2 client_credentials.
  #
  # Access tokens are cached per-account in Rails.cache for `token_cache_ttl`
  # (default 50min — GLPI tokens live 60min). On 401 we invalidate and retry once.
  class GlpiClient
    class Error          < StandardError; end
    class AuthError      < Error; end
    class NotFoundError  < Error; end
    class RemoteError    < Error; end

    def initialize(connection)
      @connection = connection
    end

    # --- Tickets -------------------------------------------------------------

    def create_ticket(payload)
      request(:post, '/Ticket', body: { input: payload })
    end

    def get_ticket(ticket_id)
      request(:get, "/Ticket/#{ticket_id}")
    end

    def update_ticket(ticket_id, payload)
      request(:put, "/Ticket/#{ticket_id}", body: { input: payload.merge(id: ticket_id) })
    end

    def add_followup(ticket_id, content, is_private: false)
      request(:post, '/ITILFollowup', body: {
        input: {
          itemtype: 'Ticket',
          items_id: ticket_id,
          content: content,
          is_private: is_private ? 1 : 0
        }
      })
    end

    # --- Connectivity probe --------------------------------------------------

    def ping
      token!   # raises if we can't authenticate
      request(:get, '/getMyProfiles')
      true
    end

    # --- Internals -----------------------------------------------------------

    private

    def http
      @http ||= Faraday.new(url: @connection.api_url) do |f|
        f.request  :json
        f.response :json, content_type: /\bjson$/
        f.request  :retry, max: 2, interval: 0.3, backoff_factor: 2,
                           retry_statuses: [429, 502, 503, 504]
        f.adapter Faraday.default_adapter
      end
    end

    def request(method, path, body: nil)
      do_request(method, path, body, allow_retry: true)
    end

    def do_request(method, path, body, allow_retry:)
      response = http.run_request(method, path, body&.to_json, headers)
      return response.body if response.success?

      case response.status
      when 401
        raise AuthError, "401 from GLPI: #{response.body}" unless allow_retry

        invalidate_token!
        return do_request(method, path, body, allow_retry: false)
      when 404
        raise NotFoundError, "404 from GLPI #{path}"
      else
        raise RemoteError, "GLPI #{response.status}: #{response.body.inspect}"
      end
    end

    def headers
      {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{token!}"
      }
    end

    def cache_key
      "glpi:token:#{@connection.account_id}"
    end

    def token!
      cached = Rails.cache.read(cache_key)
      return cached if cached.present?

      fresh = fetch_token!
      Rails.cache.write(cache_key, fresh, expires_in: ChatwootGlpiIntegration.configuration.token_cache_ttl)
      fresh
    end

    def invalidate_token!
      Rails.cache.delete(cache_key)
    end

    def fetch_token!
      resp = Faraday.post(
        @connection.token_endpoint,
        URI.encode_www_form(
          grant_type:    'client_credentials',
          client_id:     @connection.client_id,
          client_secret: @connection.client_secret,
          scope:         @connection.scope.presence || 'api'
        ),
        'Content-Type' => 'application/x-www-form-urlencoded'
      )
      raise AuthError, "Token endpoint #{resp.status}: #{resp.body}" unless resp.success?

      payload = JSON.parse(resp.body)
      token   = payload['access_token']
      raise AuthError, 'No access_token in response' if token.blank?

      @connection.update_column(:last_handshake_at, Time.current)
      token
    end
  end
end
