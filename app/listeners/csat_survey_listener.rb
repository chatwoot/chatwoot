class CsatSurveyListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]

    return unless conversation.resolved?

    # The event carries the assignee as it was when the status change was
    # dispatched - the conversation itself is reloaded here and may already
    # have been unassigned by an automation running off the resolved event.
    CsatSurveyService.new(conversation: conversation, assignee_id: event.data[:assignee_id]).perform
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    return unless message.input_csat?

    CsatSurveys::ResponseBuilder.new(message: message).perform
  end
end
