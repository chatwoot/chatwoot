class Whatsapp::Providers::WhatsappCloudLocationService < Whatsapp::Providers::BaseService
  def self.perform(whatsapp_channel, identifier, message)
    new(whatsapp_channel: whatsapp_channel).perform(identifier, message)
  end

  def perform(identifier, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: reply_context(message),
        **recipient_params(identifier),
        type: 'location',
        location: message.content_attributes['whatsapp_location'].slice('latitude', 'longitude', 'name', 'address')
      }.to_json
    )

    process_response(response, message)
  end

  private

  def phone_id_path
    api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    base_url = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    "#{base_url}/#{api_version}/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    { message_id: reply_to } if reply_to.present?
  end

  def error_message(response)
    response.parsed_response.dig('error', 'message') if response.parsed_response.is_a?(Hash)
  end
end
