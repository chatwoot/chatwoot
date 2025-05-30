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
    conversation_allows_csat? && csat_enabled? && !csat_already_sent?
  end

  def conversation_allows_csat?
    conversation.resolved? && !conversation.tweet?
  end

  def csat_enabled?
    inbox.csat_survey_enabled?
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
