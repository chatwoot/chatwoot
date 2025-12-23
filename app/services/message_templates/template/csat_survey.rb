class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def csat_survey_message_params
    content_text = csat_content_text

    params = {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: content_text,
      content_attributes: {
        csat_format: inbox.csat_format,
        question_text: content_text
      }
    }

    add_sender_info(params)
    params
  end

  def csat_content_text
    if inbox.csat_yes_no_format? && inbox.csat_question_text.present?
      inbox.csat_question_text
    else
      I18n.t('conversations.templates.csat_input_message_body')
    end
  end

  def add_sender_info(params)
    sender = resolving_agent
    return unless sender

    params[:sender_type] = sender.class.name
    params[:sender_id] = sender.id
  end

  def resolving_agent
    # Try to get the current user (agent who is resolving the conversation)
    # Fall back to conversation assignee if Current.user is not available
    Current.user || @conversation.assignee
  end
end
