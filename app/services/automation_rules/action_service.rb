class AutomationRules::ActionService < ActionService
  def initialize(rule, account, conversation, message: nil)
    super(conversation)
    @rule = rule
    @message = message
    @account = account
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @conversation.reload
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  # The sync AgentBotListener already ran for this message against the previous bot, so a bot assigned
  # here would never receive the message that routed the conversation to it.
  def assign_agent_bot(agent_bot_ids = [])
    previous_bot = bot_that_got_the_message
    bot = super
    message = message_to_forward
    return if message.nil? || bot.nil? || bot == previous_bot
    return unless message.webhook_sendable? && bot.outgoing_url.present?

    AgentBots::WebhookJob.perform_later(bot.outgoing_url, message.webhook_data.merge(event: 'message_created'),
                                        :agent_bot_webhook, secret: bot.secret, delivery_id: SecureRandom.uuid)
  end

  # Mirrors AgentBotListener#agent_bots_for.
  def bot_that_got_the_message
    return @conversation.ai_assignee if @conversation.assignee_type == 'AgentBot'

    agent_bot_inbox = @conversation.inbox.agent_bot_inbox
    agent_bot_inbox.agent_bot if agent_bot_inbox&.active?
  end

  # A channel can create the first message before this async rule runs, and conversation events carry no message.
  def message_to_forward
    return @message if @message
    return unless @rule.event_name == 'conversation_created'

    @conversation.messages.incoming.first
  end

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    blobs = @rule.files.blobs.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url[0], payload)
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation, params).perform
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true, content_attributes: { automation_rule_id: @rule.id } }
    Messages::MessageBuilder.new(nil, @conversation.reload, params).perform
  end

  def send_email_to_team(params)
    teams = @account.teams.where(id: params[0][:team_ids])

    teams.each do |team|
      break unless @account.within_email_rate_limit?

      TeamNotifications::AutomationNotificationMailer.conversation_creation(@conversation, team, params[0][:message])&.deliver_now
      @account.increment_email_sent_count
    end
  end
end
