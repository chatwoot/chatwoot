class CsatSurveys::ResponseBuilder
  pattr_initialize [:message]

  def perform
    raise 'Invalid Message' unless message.input_csat?

    conversation = message.conversation
    rating = message.content_attributes.dig('submitted_values', 'csat_survey_response', 'rating')
    feedback_message = message.content_attributes.dig('submitted_values', 'csat_survey_response', 'feedback_message')

    return if rating.blank?

    process_csat_response(conversation, rating, feedback_message)
  end

  private

  def process_csat_response(conversation, rating, feedback_message)
    csat_survey_response = message.csat_survey_response || CsatSurveyResponse.new(
      message_id: message.id, account_id: message.account_id, conversation_id: message.conversation_id,
      contact_id: conversation.contact_id, assigned_agent: conversation.assignee
    )

    update_message_content_attributes
    csat_survey_response.csat_template_id = csat_template_question.csat_template_id
    csat_survey_response.csat_template_question_id = csat_template_question.id
    csat_survey_response.rating = rating
    csat_survey_response.feedback_message = feedback_message
    csat_survey_response.save!
    csat_survey_response
  end

  def csat_template_question
    @csat_template_question ||= (message.csat_template_question || CsatTemplateQuestion.load_by_content(message.content))
  end

  def update_message_content_attributes
    return unless (attrs = message.content_attributes.dig(:submitted_values)).present?

    attrs['csat_template_question_id'] = csat_template_question&.id
    message.update_column(:content_attributes, attrs)
  end
end
