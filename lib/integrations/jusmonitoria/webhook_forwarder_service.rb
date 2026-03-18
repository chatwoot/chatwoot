# frozen_string_literal: true

# lib/integrations/jusmonitoria/webhook_forwarder_service.rb
# Fire-and-forget HTTP forwarder to JusMonitorIA.
# POSTs events to the unified endpoint POST /api/v1/integrations/chatwit.

class Integrations::Jusmonitoria::WebhookForwarderService
  TIMEOUT = 15

  class << self
    def forward_event(event_type:, payload:, account: nil)
      endpoint = jusmonitoria_endpoint
      return if endpoint.blank?

      body = {
        event_type: event_type,
        data: payload,
        metadata: build_metadata(account)
      }

      Rails.logger.info "[JUSMONITORIA-FORWARD] Sending #{event_type} to #{endpoint}"

      response = HTTParty.post(
        "#{endpoint}/api/v1/integrations/chatwit",
        headers: request_headers,
        body: body.to_json,
        timeout: TIMEOUT
      )

      Rails.logger.info "[JUSMONITORIA-FORWARD] Response: #{response.code}"
      response
    rescue StandardError => e
      Rails.logger.error "[JUSMONITORIA-FORWARD] Failed to forward #{event_type}: #{e.class}: #{e.message}"
      nil
    end

    private

    def jusmonitoria_endpoint
      ENV.fetch('JUSMONITORIA_WEBHOOK_URL', 'https://jusmonitoria.witdev.com.br')
    end

    def request_headers
      headers = { 'Content-Type' => 'application/json' }
      secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
      headers['X-Chatwit-Secret'] = secret if secret.present?
      headers
    end

    def build_metadata(account)
      {
        account_id: account&.id,
        account_name: account&.name,
        chatwit_base_url: ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br'),
        chatwit_agent_bot_token: Chatwit::JusmonitoriaBot.token,
        timestamp: Time.current.iso8601
      }
    end
  end
end
