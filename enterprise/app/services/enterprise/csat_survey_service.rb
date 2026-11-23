module Enterprise::CsatSurveyService
  private

  # A conversation Captain closed while waiting on the customer was never answered, so it gets no survey.
  # The survey goes out normally once the customer writes again and the conversation is resolved later.
  def should_send_csat_survey?
    super && !conversation.captain_waiting_close_without_reply?
  end
end
