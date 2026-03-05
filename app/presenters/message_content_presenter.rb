class MessageContentPresenter < SimpleDelegator
  def outgoing_content
    content_to_send = if should_append_survey_link?
                        survey_link = survey_url(conversation.uuid)
                        custom_message = inbox.csat_config&.dig('message')
                        custom_message.present? ? "#{custom_message} #{survey_link}" : I18n.t('conversations.survey.response', link: survey_link)
                      else
                        translated_outgoing_content || content
                      end

    Messages::MarkdownRendererService.new(
      content_to_send,
      conversation.inbox.channel_type,
      conversation.inbox.channel
    ).render
  end

  private

  def translated_outgoing_content
    return unless outgoing?
    return unless auto_translate_outgoing_enabled?

    target_language = conversation_language
    return if target_language.blank?

    translations&.[](target_language)
  end

  def auto_translate_outgoing_enabled?
    hook = google_translate_hook
    hook&.enabled? && hook.settings&.[]('auto_translate_outgoing') == true
  end

  def google_translate_hook
    @google_translate_hook ||= account.hooks.find_by(app_id: 'google_translate')
  end

  def conversation_language
    conversation.additional_attributes['conversation_language']&.tr('-', '_')
  end

  def should_append_survey_link?
    input_csat? && !inbox.web_widget?
  end

  def survey_url(conversation_uuid)
    "#{ENV.fetch('FRONTEND_URL', nil)}/survey/responses/#{conversation_uuid}"
  end
end
