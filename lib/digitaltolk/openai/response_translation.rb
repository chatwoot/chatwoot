class Digitaltolk::Openai::ResponseTranslation < Digitaltolk::Openai::Base
  attr_accessor :message, :target_language

  SYSTEM_PROMPT = %(
    You are a translation agent.
    Your main task is to translate messages between English and %<target_language>s.
    You will detect the language codes present in the <customer_message> and <agent_message>.
    You will detect if the agent needs this translation.

    You will be given:
      An agent message
      A customer message

    Perform the following tasks:
    - Detect any languages used in the <customer_message>.
      - If any clearly identifiable %<target_language>s or English phrases are present—even in subject lines or quoted text—include their language codes.
      - Also detect for other languages besides english and %<target_language>s.
      - Store all detected language codes (e.g., "en", "sv") in an array.
      - Arrange the array in order of usage, with the most prominent language at the beginning.
      - Assign this array to the <customer_message_locale> field.
      - Always return <customer_message_locale> as an array.

    - Detect the languages used in <agent_message>
      - If any clearly identifiable %<target_language>s or English phrases are present—even in subject lines or quoted text—include their language codes.
      - Also detect for other languages besides english and %<target_language>s.
      - Store all detected language codes (e.g., "en", "sv") in an array.
      - Arrange the array in order of usage, with the most prominent language at the beginning.
      - Assign this array in the <agent_message_locale> field.
      - Always return <agent_message_locale> as an array.

    - Perform language translation
      - Assign the first language code in <agent_message_locale> to the variable <dominant_agent_message_locale>.
      - If the <dominant_agent_message_locale> is English ("en"), translate the <agent_message> to %<target_language>s.
      - If the <dominant_agent_message_locale> is %<target_language>s, translate the <agent_message> to English.
      - If the <dominant_agent_message_locale> is neither English ("en") nor %<target_language>s,
        - Assign the first language code in <customer_message_locale> to the variable <dominant_customer_message_locale>.
        - Translate the <agent_message> to <dominant_customer_message_locale>.
      - Maintain the original meaning and context in the translation.
      - Always preserve the line breaks and formatting in <agent_message> to the <translated_agent_message>.
      - Do not shorten or summarize the <translated_agent_message>.
      - Store the translated agent message in <translated_agent_message>.
      - Detect the language of the <translated_agent_message> and store the language code in <translated_agent_message_locale>.

    - Perform needs_translation check
      - compare <customer_message> language and <agent_message> language and determine if <agent_message> needs to be translated
      - return true if <customer_message> and <agent_message> are in different languages
      - return false if <customer_message> and <agent_message> are in the same language
      - return true on uncertainity
      - store the boolean value in <needs_translation> field

    Response format:
    {
      "translated_agent_message": "<translated_agent_message>",
      "translated_agent_message_locale": "<translated_agent_message_locale>",
      "customer_message_locale": "<customer_message_locale>",
      "agent_message_locale": "<agent_message_locale>",
      "needs_translation": <needs_translation>,
      "dominant_customer_message_locale": "<dominant_customer_message_locale>",
      "dominant_agent_message_locale": "<dominant_agent_message_locale>"
    }

    Important:
    Return a valid json object, do not include any additional text, explanations, white spaces or formatting around the json object.
  ).freeze

  USER_PROMPT = %(%s: "%s").freeze

  def perform(content, previous_message, target_language = 'Svenska (sv)')
    @content = content
    @previous_message = previous_message
    @target_language = target_language
    return {} if @content.blank?

    response = parse_response(call_openai)
    JSON.parse response.with_indifferent_access.dig(:choices, 0, :message, :content)
  rescue StandardError => e
    Rails.logger.error e
    {}
  end

  private

  def system_prompt
    format(SYSTEM_PROMPT, target_language: @target_language)
  end

  def user_prompt
    nil
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: format(USER_PROMPT, 'customer_message', @previous_message) },
      { role: 'user', content: format(USER_PROMPT, 'agent_message', @content) }
    ]
  end
end
