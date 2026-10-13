class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    return send_template_message if template_params.present?
    return send_interactive_message if whatsapp_interactive_message?
    return send_session_message if message.conversation.can_reply?

    message.update!(status: :failed, external_error: I18n.t('errors.whatsapp.message_outside_messaging_window'))
  end

  def send_interactive_message
    Whatsapp::InteractiveMessages::Eligibility.new(message.conversation).ensure_available!(interactive_type)
    send_session_message
  rescue Whatsapp::InteractiveMessages::EligibilityError => e
    message.update!(status: :failed, external_error: e.reason)
  end

  def whatsapp_interactive_message?
    Whatsapp::InteractiveMessages::Eligibility::TYPE_FEATURES.key?(interactive_type)
  end

  def interactive_type
    message.content_attributes.dig('whatsapp_interactive', 'type')
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

    message_id = channel.send_template(message.conversation.contact_inbox.source_id, {
                                         name: name,
                                         namespace: namespace,
                                         lang_code: lang_code,
                                         parameters: processed_parameters
                                       }, message)
    complete_send(message_id)
  rescue Whatsapp::TemplateProcessorService::ValidationError => e
    message.update!(status: :failed, external_error: e.message)
  end

  def send_session_message
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    complete_send(message_id)
  end

  def complete_send(message_id)
    return if message_id.blank?

    attributes = message.content_attributes.deep_dup
    attributes.delete('external_error')
    delivery = attributes['whatsapp_delivery'].to_h
    delivery.delete('provider_error')
    attributes['whatsapp_delivery'] = delivery if attributes.key?('whatsapp_delivery')
    message.update!(source_id: message_id, status: :sent, content_attributes: attributes)
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end
end
