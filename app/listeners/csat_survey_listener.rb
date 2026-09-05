class CsatSurveyListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]

    return unless conversation.resolved?
    return if csat_on_resolve_disabled?(conversation)

    CsatSurveyService.new(conversation: conversation).perform
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    return unless message.input_csat?

    CsatSurveys::ResponseBuilder.new(message: message).perform
  end

  private

  def csat_on_resolve_disabled?(conversation)
    conversation.inbox.csat_config&.fetch('csat_on_resolve_enabled', true) == false
  end
end
