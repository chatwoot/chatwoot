class Whatsapp::Providers::WhatsappCloudCtaUrlService < Whatsapp::Providers::BaseService
  def self.perform(whatsapp_channel, phone_number, message)
    new(whatsapp_channel: whatsapp_channel).perform(phone_number, message)
  end

  def self.cta_url?(message)
    return false unless message.content_attributes.is_a?(Hash)

    cta_params = message.content_attributes['whatsapp_cta_url'] || message.content_attributes[:whatsapp_cta_url]
    return false unless cta_params.is_a?(Hash)

    (cta_params[:display_text] || cta_params['display_text']).present? &&
      (cta_params[:url] || cta_params['url']).present?
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

  def phone_id_path
    api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    base_url = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    "#{base_url}/#{api_version}/#{whatsapp_channel.provider_config['phone_number_id']}"
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
    body_text = resolve_cta_body_text(message, params)

    interactive = {
      type: 'cta_url',
      body: { text: body_text },
      action: {
        name: 'cta_url',
        parameters: {
          display_text: params[:display_text],
          url: params[:url]
        }
      }
    }
    attach_cta_header(interactive, params)
    attach_cta_footer(interactive, params)
    interactive
  end

  def resolve_cta_body_text(message, params)
    return ContentAttributeValidator.rendered_whatsapp_body(params[:body], whatsapp_channel) if params[:body].present?

    (message.respond_to?(:outgoing_content) ? message.outgoing_content.presence : nil) || message.content
  end

  def attach_cta_header(interactive, params)
    if params[:header_image].present?
      interactive[:header] = {
        type: 'image',
        image: { link: params[:header_image] }
      }
    elsif params[:header].present?
      interactive[:header] = {
        type: 'text',
        text: params[:header]
      }
    end
  end

  def attach_cta_footer(interactive, params)
    return if params[:footer].blank?

    interactive[:footer] = { text: params[:footer] }
  end
end

Whatsapp::Providers::WhatsappCloudCtaUrlService.prepend_mod_with('Whatsapp::Providers::WhatsappCloudCtaUrlService')
