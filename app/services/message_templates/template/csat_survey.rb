class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_survey_message_params)
    end
  end

  private

  delegate :contact, :account, to: :conversation

  def csat_survey_message_params
    inbox = @conversation.inbox
    content_text = if inbox.csat_yes_no_format? && inbox.csat_question_text.present?
                     inbox.csat_question_text
                   else
                     I18n.t('conversations.templates.csat_input_message_body')
                   end

    {
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
  end
end
