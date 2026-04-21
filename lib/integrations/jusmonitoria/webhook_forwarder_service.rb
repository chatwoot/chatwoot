# frozen_string_literal: true

# lib/integrations/jusmonitoria/webhook_forwarder_service.rb
# Fire-and-forget HTTP forwarder to JusMonitorIA.
# POSTs events to POST /webhooks/chatwit on the platform API (api.witdev.com.br).
# Auth: HMAC-SHA256 signature in X-Chatwit-Signature header.

class Integrations::Jusmonitoria::WebhookForwarderService
  TIMEOUT = 15

  class << self
    def forward_event(event_type:, payload:, account: nil)
      endpoint = jusmonitoria_endpoint
      return if endpoint.blank?

      json_body = build_request_body(event_type, payload, account).to_json
      Rails.logger.info "[JUSMONITORIA-FORWARD] Sending #{event_type} to #{endpoint}"
      post_event(endpoint, json_body)
    rescue StandardError => e
      Rails.logger.error "[JUSMONITORIA-FORWARD] Failed to forward #{event_type}: #{e.class}: #{e.message}"
      nil
    end

    private

    def jusmonitoria_endpoint
      ENV.fetch('JUSMONITORIA_WEBHOOK_URL', 'https://api.witdev.com.br')
    end

    def build_request_body(event_type, payload, account)
      {
        event_type: event_type,
        data: payload,
        metadata: build_metadata(account)
      }
    end

    def post_event(endpoint, json_body)
      response = HTTParty.post(
        "#{endpoint}/webhooks/chatwit",
        headers: request_headers(json_body),
        body: json_body,
        timeout: TIMEOUT
      )
      Rails.logger.info "[JUSMONITORIA-FORWARD] Response: #{response.code}"
      response
    end

    def request_headers(body)
      headers = { 'Content-Type' => 'application/json' }
      secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
      if secret.present?
        headers['x-webhook-secret'] = secret
        signature = OpenSSL::HMAC.hexdigest('SHA256', secret, body)
        headers['X-Chatwit-Signature'] = signature
      end
      headers
    end

    def build_metadata(account)
      {
        account_id: account&.id,
        account_name: account&.name,
        chatwit_base_url: ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br'),
        chatwit_agent_bot_token: Chatwit::PlatformBot.token,
        timestamp: Time.current.iso8601
      }
    end
  end
end
