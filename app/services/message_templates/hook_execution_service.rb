class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    Rails.logger.info("conversation.last_incoming_message.blank?, #{conversation.last_incoming_message.blank?}")
    return if conversation.campaign.present?
    return if conversation.last_incoming_message.blank?

    Rails.logger.info("MessageAllInfo, #{message.inspect}")
    # Prevent CSAT messages from triggering more CSAT logic to avoid loops
    return if message.content_type == 'input_csat'

    trigger_templates
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def trigger_templates
    ::MessageTemplates::Template::OutOfOffice.new(conversation: conversation).perform if should_send_out_of_office_message?
    ::MessageTemplates::Template::Greeting.new(conversation: conversation).perform if should_send_greeting?
    # ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if inbox.enable_email_collect && should_send_email_collect?
    # ::MessageTemplates::Template::PhoneCollect.new(conversation: conversation).perform if inbox.enable_email_collect && should_send_phone_collect?
    Rails.logger.info("should_send_csat_survey?, #{should_send_csat_survey?}")

    return unless should_send_csat_survey?

    ::MessageTemplates::Template::CsatSurvey.new(conversation: conversation).perform

    return unless should_use_custom_csat?

    ::CustomCsatService.new(conversation: conversation).perform
  end

  def should_send_out_of_office_message?
    # should not send if its a tweet message
    return false if conversation.tweet?
    # should not send for outbound messages
    return false unless message.incoming?

    inbox.out_of_office? && conversation.messages.today.template.empty? && inbox.out_of_office_message.present?
  end

  def first_message_from_contact?
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end

  def should_send_greeting?
    # should not send if its a tweet message
    return false if conversation.tweet?

    first_message_from_contact? && inbox.greeting_enabled? && inbox.greeting_message.present?
  end

  def email_collect_was_sent?
    conversation.messages.where(content_type: 'input_email').present?
  end

  def phone_collect_was_sent?
    conversation.messages.where(content_type: 'input_phone').present?
  end

  # TODO: we should be able to reduce this logic once we have a toggle for email collect messages
  def should_send_email_collect?
    !contact_has_email? && inbox.web_widget? && !email_collect_was_sent?
  end

  def should_send_phone_collect?
    !contact_has_phone? && inbox.web_widget? && !phone_collect_was_sent?
  end

  def contact_has_email?
    contact.email
  end

  def contact_has_phone?
    contact.phone_number
  end

  def csat_enabled_conversation?
    return false unless conversation.resolved?
    # should not sent since the link will be public
    return false if conversation.tweet?
    return false unless inbox.csat_survey_enabled?

    true
  end

  def should_send_csat_survey?
    Rails.logger.info("csat_enabled_conversation?, #{csat_enabled_conversation?}")
    return unless csat_enabled_conversation?

    # Get all CSAT messages in conversation
    csat_messages = conversation.messages.where(content_type: :input_csat)
    filtered_messages = csat_messages.where("additional_attributes->>'ignore_automation_rules' IS NULL")

    # If no previous CSAT, allow sending (original behavior)
    return true if filtered_messages.empty?

    # If inbox doesn't allow resend after expiry, block sending (original behavior)
    return false unless inbox.csat_allow_resend_after_expiry?

    # Check if the latest CSAT message is expired (new expiry feature)
    latest_csat = filtered_messages.order(created_at: :desc).first
    if csat_expired?(latest_csat)
      # Mark the previous CSAT message as ignored before sending new one
      mark_previous_csat_as_ignored(latest_csat)
      return true
    end

    false
  end

  def should_use_custom_csat?
    return false unless inbox.channel.is_a?(Channel::Api)
    return false unless inbox.channel.additional_attributes['enable_csat_on_whatsapp'] == true

    true
  end

  def csat_expired?(csat_message)
    return false unless csat_message && inbox.csat_expiry_enabled?

    expiry_time = inbox.csat_expires_after
    Time.zone.now - csat_message.created_at > expiry_time
  end

  def mark_previous_csat_as_ignored(csat_message)
    return unless csat_message

    # Update the previous CSAT message to ignore it in future automation rules
    updated_attributes = csat_message.additional_attributes || {}
    updated_attributes['ignore_automation_rules'] = true
    csat_message.update!(additional_attributes: updated_attributes)
    Rails.logger.info("Marked previous CSAT message #{csat_message.id} as ignored")
  end
end
MessageTemplates::HookExecutionService.prepend_mod_with('MessageTemplates::HookExecutionService')
