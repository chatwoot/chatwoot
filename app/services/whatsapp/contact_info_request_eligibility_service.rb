class Whatsapp::ContactInfoRequestEligibilityService
  pattr_initialize [:conversation!, :message, { delivery_mode: :any, template_params: nil, pending_request: nil, can_reply: nil }]

  class << self
    def availability_by_conversation(conversations)
      conversations = conversations.to_a
      pending_contact_inbox_ids = pending_request_contact_inbox_ids(conversations)

      conversations.to_h do |conversation|
        availability = new(
          conversation: conversation,
          pending_request: pending_contact_inbox_ids.include?(conversation.contact_inbox_id)
        ).availability
        [conversation.id, availability]
      end
    end

    private

    def pending_request_contact_inbox_ids(conversations)
      contact_inbox_ids = conversations.filter_map(&:contact_inbox_id).uniq
      return [] if contact_inbox_ids.empty?

      Message.outgoing.joins(:conversation)
             .where(conversations: { contact_inbox_id: contact_inbox_ids })
             .where.not(status: :failed)
             .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'type' = ?", 'request')
             .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'state' = ?", 'pending')
             .reorder(nil)
             .distinct
             .pluck('conversations.contact_inbox_id')
    end
  end

  def ensure_available!
    return if reason.blank?

    raise CustomExceptions::WhatsappContactInfoRequestError, { reason: reason }
  end

  def availability
    unavailable_reason = reason
    {
      available: unavailable_reason.blank?,
      reason: unavailable_reason&.to_s,
      delivery_mode: unavailable_reason.blank? ? available_delivery_mode : nil
    }
  end

  def reason
    request_reason || delivery_mode_reason
  end

  def request_contact_info_template?(params)
    request_contact_info_template(params).present?
  end

  private

  def request_reason
    return :unsupported_provider unless whatsapp_cloud_channel?
    return :phone_already_available if conversation.contact.phone_number.present?
    return :invalid_identifier unless bsuid_contact?
    return :pending_request if pending_request?
  end

  def delivery_mode_reason
    return :outside_messaging_window if delivery_mode == :interactive && !can_reply?
    return :template_not_configured if delivery_mode == :template && !request_contact_info_template?(template_params)
    return :template_not_configured if delivery_mode == :any && available_delivery_mode.blank?
  end

  def available_delivery_mode
    return @available_delivery_mode if defined?(@available_delivery_mode)

    @available_delivery_mode = if can_reply?
                                 'interactive'
                               elsif request_contact_info_templates.any?
                                 'template'
                               end
  end

  def can_reply?
    return can_reply unless can_reply.nil?

    conversation.can_reply?
  end

  def whatsapp_cloud_channel?
    conversation.inbox.channel_type == 'Channel::Whatsapp' && conversation.inbox.channel.provider == 'whatsapp_cloud'
  end

  def bsuid_contact?
    conversation.contact_inbox.source_id.to_s.match?(RegexHelper::WHATSAPP_BSUID_REGEX)
  end

  def request_contact_info_template(params)
    return if params.blank?

    request_contact_info_templates.find do |template|
      template['name'] == params['name'] && template['language']&.casecmp?(params['language'])
    end
  end

  def request_contact_info_templates
    Array(conversation.inbox.channel.message_templates).select { |template| request_contact_info_template_definition?(template) }
  end

  def request_contact_info_template_definition?(template)
    return false unless template['status'].to_s.casecmp?('approved')

    request_contact_info_buttons(template).any? { |button| button['type'].to_s.casecmp?('request_contact_info') }
  end

  def request_contact_info_buttons(template)
    buttons = Array(template['components']).find { |component| component['type'].to_s.casecmp?('buttons') }
    Array(buttons&.dig('buttons'))
  end

  def pending_request?
    return pending_request unless pending_request.nil?

    scope = Message.outgoing.where(conversation_id: conversation.contact_inbox.conversations.select(:id))
                   .where.not(status: :failed)
                   .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'type' = ?", 'request')
                   .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'state' = ?", 'pending')
    scope = scope.where.not(id: message.id) if message&.persisted?
    scope.exists?
  end
end
