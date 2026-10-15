class Whatsapp::Providers::WhatsappCloudCatalogService < Whatsapp::Providers::BaseService
  API_VERSION = 'v24.0'.freeze

  def self.perform(whatsapp_channel, identifier, message)
    new(whatsapp_channel: whatsapp_channel).perform(identifier, message)
  end

  def perform(identifier, message)
    raise Whatsapp::CatalogMessagePayloadBuilder::Error, I18n.t('errors.whatsapp.catalog.attachments_not_supported') if message.attachments.present?

    payload = Whatsapp::CatalogMessagePayloadBuilder.new(
      body: message.outgoing_content.presence, catalog: message.content_attributes['whatsapp_catalog']
    ).perform

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: { messaging_product: 'whatsapp', **recipient_params(identifier), interactive: payload, type: 'interactive' }.to_json
    )

    process_response(response, message)
  rescue Whatsapp::CatalogMessagePayloadBuilder::Error => e
    message.update!(status: :failed, external_error: e.message)
    nil
  end

  private

  def phone_id_path
    base_url = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    "#{base_url}/#{API_VERSION}/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end
end
