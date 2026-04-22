module Synapseos
  class WebhookDeliveryJob < ApplicationJob
    queue_as :default

    # Retry transient failures with exponential backoff (max 5 attempts).
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(url, payload_hash)
      return Rails.logger.warn('[Synapseos::WebhookDeliveryJob] skipping dispatch: url is blank') if url.blank?

      body = payload_hash.to_json
      signature = ::Synapseos::WebhookSigner.sign(body, ENV.fetch('SYNAPSEOS_WEBHOOK_SECRET', ''))

      response = HTTParty.post(
        url,
        body: body,
        headers: {
          'Content-Type' => 'application/json',
          'X-Synapseos-Signature' => signature
        },
        timeout: 10
      )

      return if response.code.to_i.between?(200, 299)

      raise "Synapseos webhook failed: HTTP #{response.code} from #{url}"
    end
  end
end
