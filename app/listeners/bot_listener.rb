class BotListener
  def initialize(message)
    @message = message
    @conversation = message.conversation
    @account_id = @conversation.account_id
    @inbox_id = @conversation.inbox_id
  end

  def send
    return unless active_conversation

    failure_reason = pre_check_failure_reason
    return bot_failure(failure_reason) if failure_reason

    send_messages
  end

  def increment_mau_usage
    usage = find_or_create_usage
    return unless usage

    if usage.exceeded_limits?
      log_mau_limit_reached(usage)
    else
      usage.increment_mau
      notify_mau_threshold_reached(usage) if mau_threshold_reached?(usage)
    end
  end

  private

  def inbox
    @inbox ||= AgentBotInbox.find_by(status: 1, inbox_id: @inbox_id)
  end

  def ai_agent
    return nil unless inbox

    @ai_agent ||= AiAgent.find_by(id: inbox.ai_agent_id)
  end

  def subscription
    @subscription ||= Subscription.find_by(account_id: @account_id)
  end

  def usage
    return nil unless subscription

    @usage ||= SubscriptionUsage.find_or_create_by(subscription_id: subscription.id)
  end

  def active_conversation
    @active_conversation ||= Conversation.find_by(assignee_id: nil, inbox_id: @inbox_id, id: @conversation.id)
  end

  def pre_check_failure_reason
    return 'No inbox found. Please try again later.' unless inbox

    return 'No bot available! Please try again later.' unless ai_agent
    return 'No bot available! Please try again later.' if ai_agent.chat_flow_id.blank?

    return 'No subscription or usage found for account. Please try again later.' unless subscription
    return 'No subscription or usage found for account. Please try again later.' unless usage

    return 'Usage limit exceeded! Please purchase more licenses. Please try again later.' if usage.exceeded_limits?

    nil
  end

  def send_messages
    send_message = AiAgents::FlowiseService.send_message(
      question: @message.content,
      session_id: @conversation.id,
      chat_flow_id: ai_agent.chat_flow_id
    )

    return bot_failure('Failed to send message! Please try again later.') unless send_message.success?

    usage.increment_ai_responses
    Rails.logger.info("🤖 AI Response: #{send_message.body}")

    response = send_message.parsed_response

    if response.dig('json', 'is_handover')
      process_handover(response['json'])
    else
      send_reply(response['text'])
    end
  end

  def send_reply(content)
    message_created(content)
  rescue StandardError => e
    Rails.logger.error("❌ Failed to save AI reply: #{e.message}")
  end

  def bot_failure(reason)
    Rails.logger.error("❌ Bot failure: #{reason}")
    send_reply(reason)
  end

  def process_handover(data)
    Rails.logger.warn("🔁 #{data} for conversation #{@conversation.id}")

    to_handover(data)
  end

  def to_handover(data)
    agent_available = find_available_agent

    @conversation.update!(assignee_id: agent_available.id) if agent_available
    message_content = get_message_content(@conversation.inbox_id, data)

    message_created(message_content)

    Rails.logger.info("🧑‍💼 Handover completed: Conversation #{@conversation.id} assigned to Agent #{agent_available.id}")
  rescue StandardError => e
    Rails.logger.error("❌ Failed to process handover: #{e.message}")
  end

  def get_message_content(agent_available, data)
    if agent_available
      data['answer'] || 'Agent will take over the conversation.'
    else
      Rails.logger.info("❌ No available agents for inbox #{@inbox_id}")
      'No available agents to take over the conversation.'
    end
  end

  def find_available_agent
    member_ids = InboxMember.where(inbox_id: @inbox_id).pluck(:user_id)
    return nil if member_ids.empty?

    agent_id = Conversation.least_loaded_agent(@inbox_id, member_ids)
    agent_id ||= member_ids.sample

    User.find_by(id: agent_id)
  end

  def message_created(content)
    attrs = {
      content: content,
      account_id: @account_id,
      inbox_id: @conversation.inbox_id,
      conversation_id: @conversation.id,
      message_type: 1,
      content_type: 0,
      status: 0,
      sender_type: 'AiAgent'
    }

    attrs[:sender_id] = ai_agent&.id

    Message.create!(attrs)
  end

  def find_or_create_usage
    SubscriptionUsage.find_or_create_by(subscription_id: subscription.id).tap do |u|
      Rails.logger.warn("⚠️ No subscription or usage found for account #{@account_id}") unless u
    end
  end

  def mau_threshold_reached?(usage)
    subscription.max_mau + subscription.additional_mau - 10 == usage.mau_count
  end

  def notify_mau_threshold_reached(usage)
    account_user = AccountUser.find_by(account_id: @account_id)
    user = User.find_by(id: account_user.user_id)
    AdministratorNotifications::ChannelNotificationsMailer
      .notify_mau_limit(user, usage.mau_count, subscription.max_mau)
      .deliver_later
    Rails.logger.warn("Sent Notification and Email to account id: #{@account_id}")
  end

  def log_mau_limit_reached(usage)
    Rails.logger.warn("MAU limit reached for subscription #{usage.subscription_id}")
  end
end
