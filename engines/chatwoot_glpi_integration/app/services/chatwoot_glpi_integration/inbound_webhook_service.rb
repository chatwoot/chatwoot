module ChatwootGlpiIntegration
  # Verifies the GLPI webhook signature, finds the right link, enqueues a sync.
  #
  # Signature scheme expected:
  #   header X-Glpi-Signature: HMAC-SHA256(secret, raw_body)
  class InboundWebhookService
    class InvalidSignature < StandardError; end

    def initialize(connection:, raw_body:, signature:, payload:)
      @connection = connection
      @raw_body   = raw_body
      @signature  = signature
      @payload    = payload
    end

    def call
      verify_signature!
      ticket_id = @payload['ticket_id'] || @payload['items_id'] || @payload.dig('ticket', 'id')
      raise ArgumentError, 'no ticket_id in payload' if ticket_id.blank?

      link = TicketLink.find_by(account_id: @connection.account_id, glpi_ticket_id: ticket_id)
      return :no_link unless link

      SyncTicketJob.perform_later(link.id)
      :enqueued
    end

    private

    def verify_signature!
      secret = @connection.effective_webhook_secret
      raise InvalidSignature, 'no secret configured' if secret.blank?

      expected = OpenSSL::HMAC.hexdigest('SHA256', secret, @raw_body.to_s)
      raise InvalidSignature, 'bad signature' unless ActiveSupport::SecurityUtils.secure_compare(expected, @signature.to_s)
    end
  end
end
