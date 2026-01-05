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
    Rails.logger.info '[WHATSAPP_SEND] 📤 Preparing to send template message'
    Rails.logger.info "[WHATSAPP_SEND] 📋 Template params from message: #{template_params.inspect}"

    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params,
      message: message
    )

    name, namespace, lang_code, processed_parameters = processor.call

    Rails.logger.info '[WHATSAPP_SEND] ✅ Processor returned:'
    Rails.logger.info "[WHATSAPP_SEND]    - name: #{name.inspect}"
    Rails.logger.info "[WHATSAPP_SEND]    - namespace: #{namespace.inspect}"
    Rails.logger.info "[WHATSAPP_SEND]    - lang_code: #{lang_code.inspect}"
    Rails.logger.info "[WHATSAPP_SEND]    - processed_parameters: #{processed_parameters.inspect}"

    if name.blank?
      Rails.logger.error '[WHATSAPP_SEND] ❌ Template name is blank'
      message.update!(status: :failed, external_error: 'Template not found or invalid template name')
      return
    end

    Rails.logger.warn '[WHATSAPP_SEND] ⚠️  Processed parameters are blank - template might not have parameters' if processed_parameters.blank?

    template_info = {
      name: name,
      namespace: namespace,
      lang_code: lang_code,
      parameters: processed_parameters
    }

    Rails.logger.info "[WHATSAPP_SEND] 📤 Sending template with info: #{template_info.inspect}"

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
end
