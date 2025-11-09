# frozen_string_literal: true

class Labels::OpenaiClassifierService
  attr_reader :conversation, :account

  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
  end

  def suggest_label
    return nil unless should_process?

    response = call_openai_api
    response.content.fetch('label_id')
  rescue StandardError => e
    Rails.logger.error("OpenAI label classification failed: #{e.message}")
    { label_id: nil, reasoning: nil }
  end

  private

  def should_process?
    return false if available_labels.empty?

    threshold = account.settings.fetch('auto_label_message_threshold', 3)
    incoming_count = conversation.messages.incoming.count

    incoming_count >= threshold
  end

  def call_openai_api
    chat = RubyLLM.chat(model: 'gpt-4o-mini').with_temperature(0.3)
    conversation_text = build_conversation_text
    chat.with_schema(LabelClassificationSchema).ask(conversation_text)
  end

  def build_conversation_text
    # Format labels as "ID: title - description"
    labels_list = available_labels.map do |label|
      desc = label['description'].present? ? " - #{label['description']}" : ''
      "#{label['id']}: #{label['title']}#{desc}"
    end.join(', ')

    prompt = <<~PROMPT
      You are a customer support conversation classifier. Your task is to analyze the conversation
      and select the SINGLE most relevant label from the provided list.

      Available labels (ID: name):
      #{labels_list}

      Rules:
      - Select ONLY ONE label ID that is most relevant
      - The label_id must be from the list above
      - Base your decision on the conversation content and context

      Conversation:
    PROMPT

    # Add conversation messages
    conversation.messages.last(20).each do |message|
      sender = message.incoming? ? 'Customer' : 'Agent'
      prompt += "\n#{sender}: #{message.content}"
    end

    prompt
  end

  def available_labels
    @available_labels ||= account.labels.as_json(only: [:id, :title, :description])
  end
end
