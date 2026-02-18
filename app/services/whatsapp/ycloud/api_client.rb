# Shared HTTP client for all YCloud API interactions.
# Handles authentication, base URL, and common response patterns.
module Whatsapp::Ycloud
  class ApiClient
    pattr_initialize [:whatsapp_channel!]

    def get(path, params = {})
      HTTParty.get(
        "#{api_base_path}#{path}",
        headers: api_headers,
        query: params
      )
    end

    def post(path, body = {})
      HTTParty.post(
        "#{api_base_path}#{path}",
        headers: api_headers,
        body: body.to_json
      )
    end

    def patch(path, body = {})
      HTTParty.patch(
        "#{api_base_path}#{path}",
        headers: api_headers,
        body: body.to_json
      )
    end

    def delete(path)
      HTTParty.delete(
        "#{api_base_path}#{path}",
        headers: api_headers
      )
    end

    def post_multipart(path, file, content_type)
      HTTParty.post(
        "#{api_base_path}#{path}",
        headers: { 'X-API-Key' => api_key },
        multipart: true,
        body: { file: file, content_type: content_type }
      )
    end

    def api_base_path
      ENV.fetch('YCLOUD_BASE_URL', 'https://api.ycloud.com/v2')
    end

    def api_headers
      { 'X-API-Key' => api_key, 'Content-Type' => 'application/json' }
    end

    # Verify webhook signature from YCloud.
    # Header format: YCloud-Signature: t=timestamp,s=signature
    # Signature = HMAC-SHA256(webhook_secret, "timestamp.raw_body")
    def self.verify_signature(raw_body, signature_header, webhook_secret)
      return false if signature_header.blank? || webhook_secret.blank?

      parts = signature_header.split(',').to_h { |p| p.split('=', 2) }
      timestamp = parts['t']
      signature = parts['s']
      return false if timestamp.blank? || signature.blank?

      expected = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, "#{timestamp}.#{raw_body}")
      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end

    private

    def api_key
      whatsapp_channel.provider_config['api_key']
    end
  end
end
