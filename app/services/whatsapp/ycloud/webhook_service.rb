# YCloud Webhook endpoint management.
# Full CRUD for webhook endpoints, signature verification, and secret rotation.
# https://docs.ycloud.com/reference/list-webhook-endpoints
module Whatsapp::Ycloud
  class WebhookService
    pattr_initialize [:whatsapp_channel!]

    # All available YCloud webhook event types.
    ALL_EVENTS = %w[
      whatsapp.inbound_message.received
      whatsapp.message.updated
      whatsapp.business_account.updated
      whatsapp.business_account.reviewed
      whatsapp.business_account.deleted
      whatsapp.phone_number.deleted
      whatsapp.phone_number.name_updated
      whatsapp.phone_number.quality_updated
      whatsapp.template.reviewed
      whatsapp.template.category_updated
      whatsapp.template.quality_updated
      whatsapp.payment.updated
      whatsapp.call.connect
      whatsapp.call.terminate
      whatsapp.call.status.updated
      whatsapp.flow.status_change
      whatsapp.user.preferences
      whatsapp.smb.history
      whatsapp.smb.message.echoes
      whatsapp.smb.app.state.sync
      contact.created
      contact.deleted
      contact.attributes_changed
      contact.unsubscribe.created
      contact.unsubscribe.deleted
    ].freeze

    # Create a webhook endpoint.
    # @param params [Hash]:
    #   - url [String] Webhook URL
    #   - events [Array<String>] Event types to subscribe to
    #   - status [String] 'active' or 'disabled'
    def create(params)
      client.post('/webhookEndpoints', params)
    end

    # List all webhook endpoints.
    def list(page: 1, limit: 20)
      client.get('/webhookEndpoints', page: page, limit: limit)
    end

    # Retrieve a specific webhook endpoint.
    def retrieve(endpoint_id)
      client.get("/webhookEndpoints/#{endpoint_id}")
    end

    # Update a webhook endpoint (events, URL, status).
    def update(endpoint_id, params)
      client.patch("/webhookEndpoints/#{endpoint_id}", params)
    end

    # Delete a webhook endpoint.
    def delete(endpoint_id)
      client.delete("/webhookEndpoints/#{endpoint_id}")
    end

    # Rotate the webhook signing secret (for HMAC-SHA256 verification).
    def rotate_secret(endpoint_id)
      client.post("/webhookEndpoints/#{endpoint_id}/rotate-secret")
    end

    # Register webhook with all available events.
    def register_full_webhook
      webhook_url = "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{whatsapp_channel.phone_number}"
      create(url: webhook_url, events: ALL_EVENTS, status: 'active')
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
