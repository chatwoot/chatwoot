module ChatwootGlpiIntegration
  module Webhooks
    # Public endpoint — no Chatwoot auth. Verifies HMAC signature.
    # POST /webhooks/glpi/:account_id  with header X-Glpi-Signature: <hex>
    class GlpiController < ::ActionController::API
      def receive
        connection = Connection.find_by(account_id: params[:account_id], active: true)
        return head :not_found if connection.nil?

        raw_body = request.body.read
        payload  = begin
                     JSON.parse(raw_body)
                   rescue StandardError
                     {}
                   end

        InboundWebhookService.new(
          connection: connection,
          raw_body:   raw_body,
          signature:  request.headers['X-Glpi-Signature'],
          payload:    payload
        ).call

        head :no_content
      rescue InboundWebhookService::InvalidSignature
        head :unauthorized
      rescue StandardError => e
        Rails.logger.error("[Glpi webhook] #{e.class}: #{e.message}")
        head :unprocessable_entity
      end
    end
  end
end
