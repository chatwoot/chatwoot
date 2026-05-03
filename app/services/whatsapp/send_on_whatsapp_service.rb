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

    template_info = {
      name: name,
      namespace: namespace,
      lang_code: lang_code,
      parameters: processed_parameters
    }

    prepare_cloud_template_dashboard_message(template_info)

    message_id = channel.send_template(message.conversation.contact_inbox.source_id, template_info, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def send_session_message
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end

  def prepare_cloud_template_dashboard_message(template_info)
    return unless channel.provider == 'whatsapp_cloud'

    components = Array(template_info[:parameters]).map(&:deep_stringify_keys)
    template_payload = {
      'name' => template_info[:name],
      'language' => { 'code' => template_info[:lang_code] },
      'components' => components
    }
    attributes = (message.content_attributes || {}).deep_dup
    attributes.merge!(
      'template' => template_payload,
      'type' => 'template',
      'whatsapp_template_payload' => template_payload
    )

    message.update!(
      content: template_fallback_content(template_info[:name], components),
      content_type: :integrations,
      content_attributes: attributes
    )
  end

  def template_fallback_content(template_name, components)
    body_component = components.find { |component| component['type'].to_s.casecmp('body').zero? }
    body_text = Array(body_component&.dig('parameters')).filter_map { |parameter| parameter['text'].presence }.join("\n\n")

    body_text.presence || "Template: #{template_name}"
  end
end
