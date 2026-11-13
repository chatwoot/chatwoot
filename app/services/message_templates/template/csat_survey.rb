class MessageTemplates::Template::CsatSurvey
  # assigned_agent_id: who the eventual response should credit, captured by
  # the caller while it was still known. Falls back to what the conversation
  # itself can still tell us.
  pattr_initialize [:conversation!, :assigned_agent_id]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def message_content
    return I18n.t('conversations.templates.csat_input_message_body') if csat_config.blank? || csat_config['message'].blank?

    csat_config['message']
  end

  def csat_survey_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: message_content,
      content_attributes: content_attributes
    }
  end

  def csat_config
    inbox.csat_config || {}
  end

  def content_attributes
    {
      display_type: csat_config['display_type'] || 'emoji',
      # Captured when the survey is sent, not when the contact answers it:
      # by submission time an automation may long since have unassigned the
      # conversation and the response would be recorded without an agent
      # (#14872). See Conversation#csat_survey_agent_id for why the assignee
      # alone is not enough even at this point.
      assigned_agent_id: assigned_agent_id || @conversation.csat_survey_agent_id
    }
  end
end
