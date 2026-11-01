class Whatsapp::Providers::WhatsappCloudCtaUrlService < Whatsapp::Providers::BaseService
  def self.perform(whatsapp_channel, phone_number, message)
    new(whatsapp_channel: whatsapp_channel).perform(phone_number, message)
  end

  def perform(phone_number, message)
    payload = create_cta_url_payload(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        **recipient_params(phone_number),
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response, message)
  end

  private

  def phone_id_path(version = 'v13.0')
    base_url = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    "#{base_url}/#{version}/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def error_message(response)
    response.parsed_response.dig('error', 'message') if response.parsed_response.is_a?(Hash)
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  def cta_url_params(message)
    return unless message.content_attributes.is_a?(Hash)

    params = message.content_attributes['whatsapp_cta_url'] || message.content_attributes[:whatsapp_cta_url]
    params.is_a?(Hash) ? params.with_indifferent_access : nil
  end

  def create_cta_url_payload(message)
    params = cta_url_params(message)
    body_text = params[:body].presence || (message.respond_to?(:outgoing_content) ? message.outgoing_content.presence : nil) || message.content

    interactive = {
      type: 'cta_url',
      body: { text: body_text },
      action: {
        name: 'cta_url',
        parameters: {
          display_text: params[:display_text] || params[:button_label] || params[:button],
          url: params[:url] || params[:link]
        }
      }
    }
    attach_cta_header(interactive, params)
    attach_cta_footer(interactive, params)
    interactive
  end

  def attach_cta_header(interactive, params)
    if params[:header_image].present? || params[:image_url].present?
      interactive[:header] = {
        type: 'image',
        image: { link: params[:header_image] || params[:image_url] }
      }
    elsif params[:header].present? || params[:header_text].present?
      interactive[:header] = {
        type: 'text',
        text: params[:header] || params[:header_text]
      }
    end
  end

  def attach_cta_footer(interactive, params)
    footer_text = params[:footer] || params[:footer_text]
    return if footer_text.blank?

    interactive[:footer] = { text: footer_text }
  end
end

Whatsapp::Providers::WhatsappCloudCtaUrlService.prepend_mod_with('Whatsapp::Providers::WhatsappCloudCtaUrlService')
