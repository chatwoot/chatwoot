class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    should_send_template_message = template_params.present? || !message.conversation.can_reply?
    if should_send_template_message
      send_template_message
    else
      send_session_message
    end
  end

  def send_template_message
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params,
      message: message
    )

    name, namespace, lang_code, processed_parameters = processor.call

    if name.blank?
      message.update!(status: :failed, external_error: 'Template not found or invalid template name')
      return
    end

    store_template_info_on_message(name)

    message_id = channel.send_template(message.conversation.contact_inbox.source_id, {
                                         name: name,
                                         namespace: namespace,
                                         lang_code: lang_code,
                                         parameters: processed_parameters
                                       }, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def send_session_message
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end

  def store_template_info_on_message(template_name)
    template = find_synced_template(template_name)
    return unless template

    template_info = build_template_info(template)
    content_attrs = (message.content_attributes || {}).merge('template_info' => template_info)
    message.update!(content_attributes: content_attrs)
  end

  def find_synced_template(name)
    channel.message_templates&.find do |t|
      t['name'] == name &&
        t['language']&.downcase == template_params['language']&.downcase
    end
  end

  def build_template_info(template)
    info = { 'name' => template['name'] }
    extract_components(template, info)
    merge_media_url(info)
    info
  end

  def extract_components(template, info)
    template['components']&.each do |component|
      case component['type']
      when 'HEADER'
        info['header'] = build_header_info(component)
      when 'FOOTER'
        info['footer'] = component['text']
      when 'BUTTONS'
        info['buttons'] = build_buttons_info(component)
      end
    end
  end

  def merge_media_url(info)
    processed = template_params.dig('processed_params', 'header')
    return unless processed && info['header'] && processed['media_url'].present?

    info['header']['media_url'] = processed['media_url']
  end

  def build_header_info(component)
    header = { 'format' => component['format'] }
    header['text'] = component['text'] if component['text'].present?
    header
  end

  def build_buttons_info(component)
    component['buttons']&.map do |button|
      btn = { 'type' => button['type'], 'text' => button['text'] }
      btn['url'] = button['url'] if button['url'].present?
      btn['phone_number'] = button['phone_number'] if button['phone_number'].present?
      btn
    end
  end
end
