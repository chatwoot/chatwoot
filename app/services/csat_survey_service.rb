class CsatSurveyService
  pattr_initialize [:conversation!]

  def perform
    return unless should_send_csat_survey?

    if within_messaging_window?
      send_csat_survey
    else
      log_csat_not_sent_activity
    end
  end

  private

  delegate :inbox, :contact, to: :conversation

  def should_send_csat_survey?
    return false unless conversation.resolved?
    # should not send since the link will be public
    return false if conversation.tweet?
    return false unless inbox.csat_survey_enabled?
    # only send CSAT once per conversation
    return false if csat_already_sent?

    true
  end

  def csat_already_sent?
    conversation.messages.where(content_type: :input_csat).present?
  end

  def within_messaging_window?
    conversation.can_reply?
  end

  def send_csat_survey
    ::MessageTemplates::Template::CsatSurvey.new(conversation: conversation).perform
  end

  def log_csat_not_sent_activity
    conversation.create_csat_not_sent_activity_message
  end
end
