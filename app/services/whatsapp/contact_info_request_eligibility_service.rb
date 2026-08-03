class Whatsapp::ContactInfoRequestEligibilityService
  pattr_initialize [:conversation!, :message]

  def ensure_available!
    return if reason.blank?

    raise CustomExceptions::WhatsappContactInfoRequestError, { reason: reason }
  end

  def reason
    return :unsupported_provider unless whatsapp_cloud_channel?
    return :phone_already_available if conversation.contact.phone_number.present?
    return :invalid_identifier unless bsuid_contact?
    return :outside_messaging_window unless conversation.can_reply?
    return :pending_request if pending_request?
  end

  private

  def whatsapp_cloud_channel?
    conversation.inbox.channel_type == 'Channel::Whatsapp' && conversation.inbox.channel.provider == 'whatsapp_cloud'
  end

  def bsuid_contact?
    conversation.contact_inbox.source_id.to_s.match?(RegexHelper::WHATSAPP_BSUID_REGEX)
  end

  def pending_request?
    scope = conversation.messages.outgoing
                        .where.not(status: :failed)
                        .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'type' = ?", 'request')
                        .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'state' = ?", 'pending')
    scope = scope.where.not(id: message.id) if message&.persisted?
    scope.exists?
  end
end
