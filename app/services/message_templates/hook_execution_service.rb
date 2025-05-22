class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    if conversation.campaign.present?
      Rails.logger.info { "[OutOfOffice][#{conversation.id}] Not triggering templates because conversation has a campaign" }
      return
    end

    if conversation.last_incoming_message.blank?
      Rails.logger.info { "[OutOfOffice][#{conversation.id}] Not triggering templates because there is no incoming message" }
      return
    end

    Rails.logger.info "[OutOfOffice][#{conversation.id}] Triggering templates for conversation ##{conversation.id}"
    trigger_templates
  rescue StandardError => e
    Rails.logger.error "[OutOfOffice][#{conversation.id}] Error triggering templates: #{e.message}"
    raise e
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def trigger_templates
    ::MessageTemplates::Template::OutOfOffice.new(conversation: conversation).perform if should_send_out_of_office_message?
    ::MessageTemplates::Template::Greeting.new(conversation: conversation).perform if should_send_greeting?
    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if inbox.enable_email_collect && should_send_email_collect?
    ::MessageTemplates::Template::CsatSurvey.new(conversation: conversation).perform if should_send_csat_survey?
  end

  def should_send_out_of_office_message?
    # should not send if its a tweet message
    if conversation.tweet?
      Rails.logger.info { "[OutOfOffice][#{conversation.id}] Not sending out-of-office message because it's a tweet conversation" }
      return false
    end

    # should not send for outbound messages
    unless message.incoming?
      Rails.logger.info { "[OutOfOffice][#{conversation.id}] Not sending out-of-office message because the message is outgoing" }
      return false
    end

    # prevents sending out-of-office message if an agent has sent a message in last 5 minutes
    # ensures better UX by not interrupting active conversations at the end of business hours
    if conversation.messages.outgoing.exists?(['created_at > ?', 5.minutes.ago])
      Rails.logger.info { "[OutOfOffice][#{conversation.id}] Not sending out-of-office message because an agent responded in the last 5 minutes" }
      return false
    end

    can_send = inbox.out_of_office? && conversation.messages.today.template.empty? && inbox.out_of_office_message.present?

    if can_send
      Rails.logger.info "[OutOfOffice][#{conversation.id}] Sending out-of-office message for conversation ##{conversation.id}"
    else
      reasons = []
      reasons << 'inbox not in out-of-office mode' unless inbox.out_of_office?
      reasons << 'conversation already has a template message today' unless conversation.messages.today.template.empty?
      reasons << 'inbox has no out-of-office message configured' unless inbox.out_of_office_message.present?
      Rails.logger.info { "[OutOfOffice][#{conversation.id}] Not sending out-of-office message because: #{reasons.join(', ')}" }
    end

    can_send
  rescue StandardError => e
    Rails.logger.error("[OutOfOffice][#{conversation.id}] Error triggering out of office message: #{e.message}")
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    false
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

  # TODO: we should be able to reduce this logic once we have a toggle for email collect messages
  def should_send_email_collect?
    !contact_has_email? && inbox.web_widget? && !email_collect_was_sent?
  end

  def contact_has_email?
    contact.email
  end

  def csat_enabled_conversation?
    return false unless conversation.resolved?
    # should not sent since the link will be public
    return false if conversation.tweet?
    return false unless inbox.csat_survey_enabled?

    true
  end

  def should_send_csat_survey?
    return unless csat_enabled_conversation?

    # only send CSAT once in a conversation
    return if conversation.messages.where(content_type: :input_csat).present?

    true
  end
end
MessageTemplates::HookExecutionService.prepend_mod_with('MessageTemplates::HookExecutionService')
