class MessageTemplates::Template::CsatSurvey
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      new_csat = conversation.messages.create!(csat_survey_message_params)

      if csat_template_question
        new_csat.csat_template_question = csat_template_question
      end
    end
  end

  private

  delegate :contact, :account, :inbox, to: :conversation

  def csat_survey_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_csat,
      content: message_content
    }
  end

  def message_content
    custom_csat_question || I18n.t('conversations.templates.csat_input_message_body')
  end

  def custom_csat_question
    return unless account.csat_template_enabled?

    csat_template_question&.content
  end

  def csat_template_question
    return @csat_template_question if defined?(@csat_template_question)
    return unless account.csat_template_enabled?

    send_csat_count = conversation.messages.csat.count
    @csat_template_question = inbox.csat_template.csat_template_questions.offset(send_csat_count).first
  end
end
