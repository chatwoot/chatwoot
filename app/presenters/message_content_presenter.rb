class MessageContentPresenter < SimpleDelegator
  def outgoing_content
    base_content = if should_append_survey_link?
                     survey_response_message
                   else
                     content.to_s
                   end

    append_quoted_email_text(base_content)
  end

  private

  def survey_response_message
    survey_link = survey_url(conversation.uuid)
    custom_message = inbox.csat_config&.dig('message')

    custom_message.present? ? "#{custom_message} #{survey_link}" : I18n.t('conversations.survey.response', link: survey_link)
  end

  def append_quoted_email_text(base_content)
    quoted_text = quoted_email_text
    return base_content if quoted_text.blank?

    sanitized_base = base_content.to_s
    return quoted_text if sanitized_base.blank?

    separator = if sanitized_base.end_with?("\n\n")
                  ''
                elsif sanitized_base.end_with?("\n")
                  "\n"
                else
                  "\n\n"
                end

    "#{sanitized_base}#{separator}#{quoted_text}"
  end

  def quoted_email_text
    return '' unless email_inbox?

    attrs = if content_attributes.respond_to?(:with_indifferent_access)
              content_attributes.with_indifferent_access
            else
              {}
            end

    text = attrs[:quoted_email_text]
    return '' if text.blank?

    text.to_s
  end

  def email_inbox?
    inbox&.email?
  end

  def should_append_survey_link?
    input_csat? && !inbox.web_widget?
  end

  def survey_url(conversation_uuid)
    "#{ENV.fetch('FRONTEND_URL', nil)}/survey/responses/#{conversation_uuid}"
  end
end
