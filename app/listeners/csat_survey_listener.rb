class CsatSurveyListener < BaseListener
  # The status flip and the label the survey rule tests are written by two different jobs. An
  # agent who answers and resolves in the same gesture makes the automation that applies the
  # label land AFTER this listener has already read `label_list` and decided not to send:
  # measured on a production email inbox, the label arrives 2s late at p50 and 8s at the worst,
  # and 31 of 87 eligible conversations in one morning lost their survey that way. A single
  # delayed second pass covers that window, and it is scheduled only when the rules were what
  # blocked the survey, so an ordinary resolution still costs exactly one attempt.
  CSAT_RETRY_DELAY = 30.seconds

  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]

    return unless conversation.resolved?
    return unless CsatSurveyService.new(conversation: conversation).perform == :blocked_by_survey_rules

    Conversations::CsatSurveyRetryJob.set(wait: CSAT_RETRY_DELAY).perform_later(conversation)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    return unless message.input_csat?

    CsatSurveys::ResponseBuilder.new(message: message).perform
  end
end
