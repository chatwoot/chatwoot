class Captain::Copilot::MessageContext
  attr_reader :message, :conversation, :account_id, :inbox_id

  def initialize(message)
    @message = message
    @conversation = message.conversation
    @account_id = @conversation.account_id
    @inbox_id = @conversation.inbox_id
  end

  def account
    @account ||= Account.find_by(id: @account_id)
  end

  def inbox
    @inbox ||= AgentBotInbox
               .where.not(ai_agent_id: nil)
               .find_by(status: 1, inbox_id: @inbox_id)
  end

  def ai_agent
    return nil unless inbox

    @ai_agent ||= AiAgent.find_by(id: inbox.ai_agent_id)
  end

  def subscription
    @subscription ||= Subscription.active.find_by(account_id: @account_id)
  end

  def usage
    return nil unless subscription

    @usage ||= SubscriptionUsage.find_or_create_by(subscription_id: subscription.id)
  end

  def active_conversation
    @active_conversation ||= Conversation.find_by(assignee_id: nil, inbox_id: @inbox_id, id: @conversation.id)
  end
end
