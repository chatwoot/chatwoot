class Digitaltolk::Openai::HtmlTranslation::Translate < Digitaltolk::Openai::Base
  SYSTEM_PROMPT = %(
    You are a translation agent.
    You will be provided with an a list of text chunks extracted from an email message.
    You will be translating messages to %<target_language>s.
    Detect the language of the message and determine if it is in %<target_language>s.
    If the message is in %<target_language>s, return it as-is, do not rephrase the message.
    If the message is not in %<target_language>s, translate it into %<target_language>s.

    Some elements may be emojis or short phrases like "UNSUBSCRIBE"—these should be translated only if appropriate,
    or returned as-is if they are symbols or proper names.
    Maintain the original meaning and context in the translation.
    Always preserve the line breaks and formatting in the translated_message.
    If the message is in html format, ensure the html tags are preserved in the translated_message.
    Do not shorten or summarize the translated message.

    Follow this format for the each element in the array.
    {
      "<untranslated_message>": "<translated_message>",
    }

    Follow this format for the entire response:
    {
      "messages": <translated_and_untranslated_messages_object>
    }

    Return your response as a valid JSON object only.
    Do not include any additional text, explanations, white spaces or formatting of the json object.
  ).freeze

  UNTRANSLATABLE_PARENT_NODES = %w[head style script].freeze

  def perform(message, chunk_messages, target_language = 'sv', batch_index: nil)
    @message = message
    @target_language = target_language
    @chunk_messages = chunk_messages
    @batch_index = batch_index
    @translated_locale = nil
    return {} if @message.blank?

    # extract_chunks_from_html
    perform_batch_translation
    update_html_content
  rescue StandardError => e
    Rails.logger.error e
    {}
  end

  private

  def perform_batch_translation
    batch = @chunk_messages
    return if batch.blank?

    response = parse_response client.chat(
      parameters: {
        model: ai_model,
        messages: messages_by_batch(batch),
        temperature: temperature_score,
        response_format: { type: 'json_object' }
      }
    )

    @message.reload
    parsed_translations = JSON.parse(response.with_indifferent_access.dig(:choices, 0, :message, :content))
    @translated_message = translate_nodes(parsed_translations['messages'])
    @translated_locale = target_language_locale
  end

  def update_html_content
    return if @translated_message.blank?

    Messages::TranslationBuilder.new(
      @message,
      @translated_message,
      @translated_locale
    ).perform
  end

  def batch_messages(arrays)
    Digitaltolk::Openai::HtmlTranslation::BatchByContentLength.perform(arrays)
  end

  def system_prompt
    format(SYSTEM_PROMPT, target_language: @target_language)
  end

  def extract_chunks_from_html
    doc = nokogiri_parsed_content

    doc.at('body').xpath('//text()').each do |node|
      text = node.text.strip
      next if text.blank?

      parent = node.parent
      next if UNTRANSLATABLE_PARENT_NODES.include?(parent.name)

      @chunk_messages << text
    end
  end

  def translate_nodes(translated_message_hash)
    has_translation = false
    doc = nokogiri_parsed_content
    translated_batch_size = translated_message_hash.keys.count

    # Normalize: squish spaces, downcase for hash use
    normalized_translated_hash = translated_message_hash.transform_keys { |key| key.squish.downcase }

    doc.at('body').xpath('//text()').each do |node|
      text = node.text.strip
      next if text.blank?

      parent = node.parent
      next if UNTRANSLATABLE_PARENT_NODES.include?(parent.name)

      normalized_key = text.squish.downcase

      next if (trans_msg = normalized_translated_hash[normalized_key]).blank?
      next if trans_msg.downcase.squish == text.downcase.squish

      has_translation = true

      node.content = trans_msg
    end

    # Set the detected locale only if a translation was made
    # This is to avoid translation when the message is already in the target language
    set_detected_locale(has_translation)

    doc.to_html if has_translation
  end

  def set_detected_locale(has_translation)
    # If it has translation, we set the detected locale of the target language as false
    Digitaltolk::Openai::Translation::SetDetectedLocale.new(
      @message,
      target_language_locale,
      !has_translation
    ).perform
  end

  def messages; end

  def messages_by_batch(chunks)
    [
      { role: 'system', content: system_prompt },
      *chunks.map { |chunk| { role: 'user', content: chunk } }
    ]
  end

  def nokogiri_parsed_content
    Nokogiri::HTML(email_content)
  end

  def target_language_locale
    return 'sv' if @target_language.include?('Svenska')

    @target_language.to_s.downcase
  end

  def translations
    @message.translations
  end

  def email_content
    if translations.present? && translations[target_language_locale].present?
      # return partially translated content if it exists
      if translations.dig('detected_locale', target_language_locale) == false
        return translations[target_language_locale]
      end
    end

    @message.email.dig('html_content', 'full')
  end
end
