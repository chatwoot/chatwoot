class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    return if inbox.agent_bot_inbox&.active?
    return if conversation.campaign.present?

    trigger_templates
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def trigger_templates
    # TODO: let's see whether this is needed and remove this and related logic if not
    # ::MessageTemplates::Template::OutOfOffice.new(conversation: conversation).perform if should_send_out_of_office_message?
    ::MessageTemplates::Template::Greeting.new(conversation: conversation).perform if should_send_greeting?
    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if inbox.enable_email_collect && should_send_email_collect?
    ::MessageTemplates::Template::CsatSurvey.new(conversation: conversation).perform if should_send_csat_survey?
  end

  def should_send_out_of_office_message?
    inbox.out_of_office? && conversation.messages.today.template.empty? && inbox.out_of_office_message.present?
  end

  def first_message_from_contact?
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end

  def should_send_greeting?
    first_message_from_contact? && inbox.greeting_enabled? && inbox.greeting_message.present?
  end

  def email_collect_was_sent?
    conversation.messages.where(content_type: 'input_email').present?
  end

  # TODO: we should be able to reduce this logic once we have a toggle for email collect messages
  def should_send_email_collect?
    !contact_has_email? && inbox.web_widget? && !inbox.channel.pre_chat_form_enabled? && !email_collect_was_sent?
  end

  def contact_has_email?
    contact.email
  end

  def csat_enabled_inbox?
    # for now csat only available in web widget channel
    return unless inbox.web_widget?
    return unless inbox.csat_survey_enabled?

    true
  end

  def should_send_csat_survey?
    return unless conversation.resolved?
    return unless csat_enabled_inbox?
    # only send CSAT once in a conversation
    return if conversation.messages.where(content_type: :input_csat).present?

    true
  end
end
