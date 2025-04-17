# message_processor.rb
module MessageProcessor
  def self.process_contact_message(message)
    conversation = message.conversation
    inbox_id = conversation.inbox_id
    account_id = conversation.account_id

    # 🔼 Increment AI usage or return early if exceeded
    return if ai_usage_limit_reached?(account_id)

    inbox = AgentBotInbox.find_by(status: 1, inbox_id: inbox_id)
    unless inbox
      Rails.logger.warn("No inbox found for inbox_id: #{inbox_id}")
      return
    end

    agent = AiAgent.find_by(id: inbox.ai_agent_id)
    unless agent
      Rails.logger.warn("No agent found with id: #{inbox.ai_agent_id}")
      return
    end

    unless agent.chat_flow_id.present?
      Rails.logger.warn("⚠️ No chat_flow_id found for agent id: #{agent.id}")
      return
    end

    response = HTTParty.post(
      "#{ENV.fetch('FLOWISE_URL', nil)}#{agent.chat_flow_id}",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV.fetch('FLOWISE_TOKEN', nil)}"
      },
      body: {
        question: message.content,
        overrideConfig: {
          sessionId: conversation.id
        }
      }.to_json
    )

    if response.success?
      Rails.logger.info("🤖 Flowise AI Response: #{response.body}")
      flowise_reply = JSON.parse(response.body)
      send_reply_to_chatwoot(conversation, flowise_reply['text'], agent)
    else
      Rails.logger.error("❌ Error contacting Flowise: #{response.body}")
    end
  end

  def self.send_reply_to_chatwoot(conversation, text, agent)
    Message.create!(
      content: text,
      account_id: agent.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: 1,
      content_type: 0,
      sender_type: 'AiAgent',
      sender_id: agent.id,
      status: 0
    )
  rescue StandardError => e
    Rails.logger.error("❌ Failed to save AI reply to Chatwoot: #{e.message}")
  end

  def increment_usage(conversation)
    account = Account.find(conversation.account_id)
    usage = account.subscription&.subscription_usage
    return unless usage

    if usage.subscription.max_ai_responses.zero? || usage.ai_responses_count + ai_response_increment <= usage.subscription.max_ai_responses
      usage.increment_ai_responses(ai_response_increment)
    else
      Rails.logger.warn("AI response limit reached for account #{account.id}")
    end

    return unless increment_mau

    if usage.subscription.max_mau.zero? || usage.mau_count + 1 <= usage.subscription.max_mau
      usage.increment_mau
    else
      Rails.logger.warn("MAU limit reached for account #{account.id}")
    end
  end
end
