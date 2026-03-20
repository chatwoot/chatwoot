class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  include BaileysHelper

  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    should_send_template_message = template_params.present? || !message.conversation.can_reply?
    if should_send_template_message
      send_template_message
    elsif channel.provider == 'baileys'
      send_baileys_session_message
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

    message_id = channel.send_template(recipient_id, {
                                         name: name,
                                         namespace: namespace,
                                         lang_code: lang_code,
                                         parameters: processed_parameters
                                       }, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def send_baileys_session_message
    validate_announcement_mode!
    with_baileys_channel_lock_on_outgoing_message(channel.id) { send_session_message }
  end

  def validate_announcement_mode!
    return unless conversation.contact.group_type_group?
    return unless conversation.contact.additional_attributes&.dig('announce') == true
    return if inbox_admin_in_group?

    message.update!(status: :failed, external_error: 'Only administrators are allowed to send messages in this group')
    raise StandardError, 'Only admins can send messages in this group'
  end

  def inbox_admin_in_group?
    inbox_phone = channel.phone_number&.gsub(/[^\d]/, '')
    return false if inbox_phone.blank?

    admin_phones = conversation.contact.group_memberships.active.where(role: :admin)
                               .includes(:contact).filter_map { |m| m.contact.phone_number&.gsub(/[^\d]/, '') }

    admin_phones.any? { |phone| phones_match?(inbox_phone, phone) }
  end

  def phones_match?(phone_a, phone_b)
    return false if phone_a.blank? || phone_b.blank?

    phone_a == phone_b || (phone_a.length >= 8 && phone_b.length >= 8 && phone_a[-8..] == phone_b[-8..])
  end

  def send_session_message
    message_id = channel.send_message(recipient_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def recipient_id
    return message.conversation.contact_inbox.source_id unless %w[baileys zapi].include?(channel.provider)

    # NOTE: `identifier` must be in the WhatsApp LID format
    message.conversation.contact.phone_number&.gsub(/[^\d]/, '') || message.conversation.contact.identifier
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end
end
