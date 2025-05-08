class Digitaltolk::Openai::Translation < Digitaltolk::Openai::Base
  attr_accessor :message, :target_language

  SYSTEM_PROMPT = %(
    You are a traslation agent. You will be translating messages between English and %<target_language>s.
    Detect the language of the message and determine if it is in English or %<target_language>s.
    If the message is in %<target_language>s, translate it into English.
    If the message is in English, translate it into %<target_language>s.
    Maintain the original meaning and context in the translation.
    Always preserve the line breaks and formatting in the translated_message.
    Do not shorten or summarize the translated message.

    Format:
    {
      "translated_message": "<translated_message>",
      "translated_locale": "<translated_language_code>"
    }

    Important:
    Return a valid json object. Do not include any additional text, explanations, white spaces or formatting of the json object.
  ).freeze

  def perform(content, target_language = 'Svenska (sv)')
    @content = content
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

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: @content }
    ]
  end
end
