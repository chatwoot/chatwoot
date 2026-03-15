module Igaralead
  class HubClient
    class << self
      def configured?
        api_url.present? && api_key.present?
      end

      def api_url
        ENV.fetch('HUB_API_URL', nil)
      end

      def api_key
        ENV.fetch('HUB_API_KEY', nil)
      end

      def jwks_url
        ENV.fetch('HUB_JWKS_URL', nil)
      end
    end

    def initialize
      @base_url = self.class.api_url
      @api_key = self.class.api_key
    end

    def get(path, params: {})
      connection.get(path, params)&.body
    end

    def post(path, body:)
      connection.post(path) { |req| req.body = body.to_json }&.body
    end

    def put(path, body:)
      connection.put(path) { |req| req.body = body.to_json }&.body
    end

    private

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :json
        f.response :json
        f.headers['X-Api-Key'] = @api_key
        f.headers['Content-Type'] = 'application/json'
        f.adapter Faraday.default_adapter
        f.options.timeout = 10
        f.options.open_timeout = 5
      end
    end
  end
end
