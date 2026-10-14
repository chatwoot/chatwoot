module Enterprise::Messages::MessageBuilder
  MISCONFIGURED_CAPTAIN_CODES = [401, 403].freeze

  private

  def message_type
    return @message_type if @message_type == 'incoming' && voice_call_inbox? && @params[:content_type] == 'voice_call'

    super
  end

  def voice_call_inbox?
    @conversation.inbox.channel.try(:voice_enabled?)
  end

  def message_params
    params = super
    return params unless auto_translate?(params)

    translated = translate(reply_text)
    # A short reply the model hands back unchanged was already in the contact language; a detected one it could not translate.
    return params if translated == reply_text && detected_language.blank?

    attributes = params[:content_attributes] || {}
    return params.merge(content_attributes: attributes.merge(translation_failed: true)) if translated.blank? || translated == reply_text

    params.merge(
      content: with_quoted_history(translated),
      content_attributes: attributes.merge(translations: { source_locale => agent_text }, source_language: @conversation.language)
    )
  end

  def auto_translate?(params)
    return false unless @account.auto_translate_enabled? && sender.is_a?(User)

    translatable_message?(params) && translatable_conversation?
  end

  def translatable_message?(params)
    params[:message_type] == 'outgoing' && !params[:private] && reply_text.present? &&
      params[:content_type].to_s.in?(['', 'text']) && @params[:template_params].blank? && @params[:email_html_content].blank?
  end

  def rendered_content
    @rendered_content ||= process_liquid_in_email_body(@params[:content].to_s)
  end

  # The email reply box appends the quoted history as markdown quote lines; only the text above them is the agent's reply.
  def quoted_history
    @quoted_history ||= email_inbox? ? rendered_content[/^>.*\z/m].to_s : ''
  end

  def reply_text
    @reply_text ||= quoted_history.blank? ? rendered_content : rendered_content.delete_suffix(quoted_history).strip
  end

  def with_quoted_history(translated)
    quoted_history.blank? ? translated : "#{translated.strip}\n\n#{quoted_history}"
  end

  # Agents keep their own text; for email it is rendered like the sent mail so the quoted history stays collapsed.
  def agent_text
    email_inbox? ? render_email_html(normalize_email_body(rendered_content)) : rendered_content
  end

  def translatable_conversation?
    @conversation.language.present? && !Captain::Llm::MessageTranslationService.same_language?(@conversation.language, source_locale)
  end

  def translate(content)
    response = Captain::Llm::MessageTranslationService.new(
      account: @account,
      texts: [{ id: 0, content: content }],
      target_language: @conversation.language,
      conversation_display_id: @conversation.display_id
    ).perform
    # A Captain that is disabled or has no key is a setup bug and must surface; a quota or model failure must not stop replies.
    raise StandardError, response[:error] if MISCONFIGURED_CAPTAIN_CODES.include?(response[:error_code])

    translated = response[:message]&.first&.dig('text') unless response[:error]
    return translated if translated.present?

    Rails.logger.warn("[AutoTranslate] reply sent as written in conversation #{@conversation.display_id}: #{response[:error] || 'empty translation'}")
    nil
  end

  def detected_language
    return @detected_language if defined?(@detected_language)

    @detected_language = Captain::Conversation::DetectLanguageService.language_of(reply_text)
  end

  # The language the agent actually wrote in; the profile language is the fallback for texts too short to detect.
  def source_locale
    detected_language || @user.ui_settings['locale'].presence || @account.locale
  end
end
