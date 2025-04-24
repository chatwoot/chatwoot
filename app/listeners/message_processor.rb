module MessageProcessor
  def self.process_contact_message(message)
    conversation = message.conversation
    inbox_id = conversation.inbox_id
    account_id = conversation.account_id

    usage = subscription_usage_for(account_id)
    unless usage
      Rails.logger.warn("⚠️ No subscription or usage found for account #{account_id}")
      return
    end

    if usage.exceeded_limits?
      Rails.logger.warn("🚫 Subscription limits exceeded for account #{account_id}")
      return
    end

    conversation_db = Conversation.find_by(assignee_id: nil, inbox_id: inbox_id)
    unless conversation_db
      Rails.logger.warn("No active convertation bot found for inbox_id: #{inbox_id}")
      return
    end

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
      "#{ENV.fetch('FLOWISE_URL')}#{agent.chat_flow_id}",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV.fetch('FLOWISE_TOKEN')}"
      },
      body: {
        question: message.content,
        overrideConfig: {
          sessionId: conversation.id
        }
      }.to_json
    )

    if response.success?
      usage.increment_ai_responses
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

  # 🧠 Pulls or creates usage for given account_id
  def self.subscription_usage_for(account_id)
    subscription = Subscription.find_by(account_id: account_id)
    return nil unless subscription

    SubscriptionUsage.find_or_create_by(subscription_id: subscription.id)
  end

  # def self.increment_usage(conversation)
  #   Rails.logger.info("conversation inputt: #{conversation}")
  #   usage = subscription_usage_for(conversation.account_id)
  #   unless usage
  #     Rails.logger.warn("⚠️ No subscription or usage found for account #{account_id}")
  #     return
  #   end
  #   if usage.exceeded_limits?
  #     Rails.logger.warn("MAU limit reached for subscription #{usage.subscription_id}")
  #   else
  #     conversationdb = conversation.find_by(id: conversation.id)
  #     usage.increment_additional_mau if conversationdb == null
  #   end
  # end
end
