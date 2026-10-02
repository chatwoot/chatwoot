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
      contact_id: conversation.contact_id, assigned_agent: assigned_agent(conversation)
    )
    csat_survey_response.rating = rating
    csat_survey_response.feedback_message = feedback_message
    csat_survey_response.save!
    csat_survey_response
  end

  # The agent snapshotted into the survey message when it was sent, falling
  # back to the conversation's current assignee for surveys sent before the
  # snapshot existed. Reading the assignee only at submission time loses the
  # attribution whenever an automation unassigns the conversation between
  # resolution and the contact clicking the rating (#14872).
  def assigned_agent(conversation)
    snapshot_id = message.content_attributes['assigned_agent_id']
    snapshot_agent = User.find_by(id: snapshot_id) if snapshot_id.present?

    snapshot_agent || conversation.assignee
  end
end
