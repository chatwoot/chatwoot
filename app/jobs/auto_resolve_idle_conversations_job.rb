class AutoResolveIdleConversationsJob < ApplicationJob
  queue_as :default

  def perform
    cutoff_time = 5.minutes.ago

    conversations = Conversation.where(status: 0)
                                .where('conversations.updated_at < ?', cutoff_time)
                                .joins(:messages)
                                .group('conversations.id')
                                .having('MAX(messages.sender_type) = ?', 'Contact')

    conversations.find_each do |conversation|
      inbox_id = conversation.inbox_id
      inbox = AgentBotInbox.find_by(status: 1, inbox_id: inbox_id)
      next unless inbox

      agent = AiAgent.find_by(id: inbox.ai_agent_id)
      next unless agent

      prompt = <<~PROMPT
        [This is a system-generated message]

        The user has been inactive for a while. Please thank them politely and mention that the conversation is being closed due to inactivity.

        Sign the message using the bot's name if available. Only use "AI Service" if no bot name is provided.

        Based on your knowledge, generate a helpful and respectful message in the appropriate language for the conversation.
      PROMPT

      begin
        response = HTTParty.post(
          "#{ENV.fetch('FLOWISE_URL')}#{agent.chat_flow_id}",
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{ENV.fetch('FLOWISE_TOKEN')}"
          },
          body: {
            question: prompt,
            overrideConfig: {
              sessionId: conversation.id
            }
          }.to_json
        )

        parsed = JSON.parse(response.body)
        content = parsed['text'] || parsed['message'] || parsed.to_s

        Message.create!(
          content: content,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          conversation_id: conversation.id,
          message_type: 1,
          content_type: 0,
          sender_type: 'AiAgent',
          sender_id: agent.id,
          status: 0
        )

        conversation.update!(status: 1, assignee_id: nil)
      rescue StandardError => e
        Rails.logger.error("[AutoResolveIdleConversationsJob] Failed to resolve conversation ##{conversation.id}: #{e.message}")
        next
      end
    end
  end
end
