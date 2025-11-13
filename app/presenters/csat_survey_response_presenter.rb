class CsatSurveyResponsePresenter
  def initialize(csat_survey_response, message)
    @csat_survey_response = csat_survey_response
    @message = message
  end

  def webhook_data
    {
      id: @csat_survey_response.id,
      rating: @csat_survey_response.rating,
      feedback_message: @csat_survey_response.feedback_message,
      created_at: @csat_survey_response.created_at,
      conversation: conversation_data,
      contact: contact_data,
      assigned_agent: agent_data,
      message_id: @message&.id
    }
  end

  private

  def conversation
    @conversation ||= @csat_survey_response.conversation
  end

  def contact
    @contact ||= @csat_survey_response.contact
  end

  def agent
    @agent ||= @csat_survey_response.assigned_agent
  end

  def conversation_data
    {
      id: @csat_survey_response.conversation_id,
      display_id: conversation&.display_id,
      inbox_id: conversation&.inbox_id
    }
  end

  def contact_data
    return {} unless contact

    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number
    }
  end

  def agent_data
    return nil unless agent

    {
      id: agent.id,
      name: agent.name,
      email: agent.email
    }
  end
end
