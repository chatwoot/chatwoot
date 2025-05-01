class Digitaltolk::Openai::ResponseTranslation < Digitaltolk::Openai::Base
  attr_accessor :message, :target_language

  SYSTEM_PROMPT = %(
    You are a translation agent. You will be translating messages between English and %<target_language>s.
    You will be given:
    An agent message
    A customer message

    Detect the language of the agent message and store the language code in agent_message_language_code.
    Detect the language of the customer message and store the language code in customer_message_language_code.

    If the agent message is in %<target_language>s, translate it into English,
    if the agent message is in English, translate it into %<target_language>s,
    Maintain the original meaning and context in the translation.
    Do not shorten or summarize the translated response message.
    Store the translated agent message in translated_agent_message.
    Detect the language of the translated agent message and store the language code in translated_agent_message_locale.

    Response format:
    {
      translated_agent_message: <translated_agent_message>,
      translated_agent_message_locale: <translated_agent_message_locale>,
      agent_message_locale: <agent_message_language_code>,
      customer_message_locale: <customer_message_language_code>,
    }

    Important: Return a valid json object, do not include any additional text, explanations, or formatting.
  ).freeze

  USER_PROMPT = %(
    Here is the message you need to translate:
    agent_message: %s
    customer_message: %s
  ).freeze

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
    format(SYSTEM_PROMPT, target_language: @target_language, message: @content)
  end

  def user_prompt
    format(USER_PROMPT, @content, @previous_message)
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end
end
