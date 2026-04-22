module Synapseos
  # HMAC-SHA256 hex digest for outbound webhook bodies. The N8N side replays
  # the same calculation against the raw request body to validate authenticity.
  class WebhookSigner
    def self.sign(payload_json, secret)
      OpenSSL::HMAC.hexdigest('SHA256', secret.to_s, payload_json.to_s)
    end
  end
end
