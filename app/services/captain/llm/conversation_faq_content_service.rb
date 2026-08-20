class Captain::Llm::ConversationFaqContentService
  def initialize(assistant, conversation)
    @assistant = assistant
    @conversation = conversation
  end

  def generate
    [
      'Business Context:',
      JSON.pretty_generate(business_context),
      "Conversation ID: ##{conversation.display_id}",
      "Channel: #{conversation.inbox.channel.name}",
      'Message History:',
      conversation_messages
    ].join("\n")
  end

  private

  attr_reader :assistant, :conversation

  def conversation_messages
    messages = conversation
               .messages
               .where(message_type: %i[incoming outgoing], private: false)
               .order(created_at: :asc)

    return "No messages in this conversation\n" if messages.empty?

    messages.filter_map { |message| format_message(message) }.join
  end

  def format_message(message)
    return unless source_message?(message)

    message_content = message.content_for_llm
    return if message_content.blank?

    sender = human_support_reply?(message) ? 'Support Agent' : 'User'
    "#{sender}: #{message_content}\n"
  end

  def source_message?(message)
    return true if message.incoming? && message.sender_type == 'Contact'

    human_support_reply?(message)
  end

  def human_support_reply?(message)
    return false unless message.outgoing?
    return false if message.content_attributes['automation_rule_id'].present?
    return false if message.additional_attributes['campaign_id'].present?

    message.sender_type == 'User' || message.content_attributes['external_echo'].present?
  end

  def business_context
    {
      product_name: assistant.config['product_name'],
      assistant_description: assistant.description,
      instructions: assistant.config['instructions'],
      response_guidelines: assistant.response_guidelines,
      guardrails: assistant.guardrails
    }.compact
  end
end
