class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!, :existing_response]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def message_content
    return ' ' if csat_config.blank? || csat_config['message'].blank? || csat_config['message_enabled'] == false

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
    attributes = {
      display_type: csat_config['display_type'] || 'emoji'
    }
    return attributes if existing_response.blank?

    attributes.merge(
      allow_update: true,
      submitted_values: {
        csat_survey_response: {
          rating: existing_response.rating,
          feedback_message: existing_response.feedback_message
        }
      }
    )
  end
end
