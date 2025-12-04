# frozen_string_literal: true

class Whatsapp::WhapiWebhookSetupService
  def initialize(channel:, inbox_id:)
    @channel = channel
    @inbox_id = inbox_id
  end

  def perform
    validate_parameters!
    setup_webhooks
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'Inbox ID is required' if @inbox_id.blank?
    raise ArgumentError, 'Channel must be whatsapp_light provider' unless @channel.provider == 'whatsapp_light'
  end

  def setup_webhooks
    response = HTTParty.patch(
      "#{api_base_url}/settings",
      headers: api_headers,
      body: webhook_payload.to_json
    )

    unless response.success?
      error_message = response.parsed_response&.dig('message') || 'Failed to setup webhooks'
      raise "Whapi webhook setup failed: #{error_message}"
    end

    Rails.logger.info "[WHATSAPP LIGHT] Webhooks configured successfully for inbox #{@inbox_id}"
    response.parsed_response
  end

  def webhook_payload
    {
      callback_persist: true,
      media: {
        auto_download: %w[image document audio video voice sticker],
        init_avatars: true
      },
      webhooks: [
        {
          url: webhook_url,
          events: webhook_events,
          mode: 'method'
        }
      ],
      pass_through: false,
      sent_status: true
    }
  end

  def webhook_events
    [
      { type: 'statuses', method: 'post' },
      { type: 'statuses', method: 'put' },
      { type: 'chats', method: 'post' },
      { type: 'messages', method: 'post' },
      { type: 'messages', method: 'put' },
      { type: 'messages', method: 'delete' },
      { type: 'contacts', method: 'post' },
      { type: 'groups', method: 'post' },
      { type: 'presences', method: 'post' },
      { type: 'channel', method: 'post' },
      { type: 'users', method: 'post' },
      { type: 'labels', method: 'post' },
      { type: 'calls', method: 'post' }
    ]
  end

  def webhook_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    "#{frontend_url}/webhooks/whapi/#{@inbox_id}"
  end

  def api_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{@channel.provider_config['token']}"
    }
  end

  def api_base_url
    url = @channel.provider_config['api_url'] || ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')
    url.chomp('/')
  end
end
