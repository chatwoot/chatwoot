class Digitaltolk::Openai::ConversationSummary < Digitaltolk::Openai::Base
  attr_accessor :conversation

  SYSTEM_PROMPT = %(
    You are a conversation summarizer. You will be summarizing a conversation between two people.
    The conversation may contain multiple messages and different languages. Your task is to summarize the conversation in a concise and coherent manner.
    The summary should be a few sentences long and should capture the main points of the conversation.
    Maintain the original meaning and context in the summary.
    Return a translated summary of the conversation in English and %<target_language>s.

    JSON format:
    { summary: <summary>, translated_summary: <translated_summary> }

    Important: Return a json object, do not include any additional text, explanations, or formatting.
  ).freeze

  def perform(conversation, target_language = 'Svenska (sv)')
    @conversation = conversation
    @target_language = target_language

    response = parse_response(call_openai)
    JSON.parse response.with_indifferent_access.dig(:choices, 0, :message, :content)
  rescue StandardError => e
    Rails.logger.error e
    {}
  end

  private

  def conversation_messages
    @conversation.messages.where(message_type: %w[incoming outgoing]).order(:created_at)
  end

  def system_prompt
    format(SYSTEM_PROMPT, target_language: @target_language)
  end

  def user_prompt
    conversation_messages.map do |message|
      if message.incoming?
        "Customer: #{message.content}"
      else
        "Agent: #{message.content}"
      end
    end.join("\n")
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end
end
