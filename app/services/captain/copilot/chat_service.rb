class Captain::Copilot::ChatService
  include SwitchLocale

  def initialize(message)
    @message = message
    @context = Captain::Copilot::MessageContext.new(message)
    @current_account = @context.account
  end

  def perform
    switch_locale_using_account_locale do
      Rails.logger.info("Locale: #{I18n.locale}")
      return unless @context.active_conversation

      failure_reason = pre_check_failure_reason
      return send_reply_failure(failure_reason) if failure_reason

      send_messages
    end
  end

  def notify_if_long_running
    switch_locale_using_account_locale do
      return unless @context.active_conversation

      failure_reason = pre_check_failure_reason
      return send_reply_failure(failure_reason) if failure_reason

      long_running_notify
    end
  end

  private

  def pre_check_failure_reason
    return I18n.t('conversations.bot.failure') unless @context.inbox

    return I18n.t('conversations.bot.not_available_ai_agent') unless @context.ai_agent
    return I18n.t('conversations.bot.not_available_ai_agent') if @context.ai_agent.chat_flow_id.blank?

    return I18n.t('subscriptions.limit_reached') unless @context.subscription
    return I18n.t('subscriptions.limit_reached') unless @context.usage

    return I18n.t('subscriptions.limit_reached') if @context.usage.exceeded_limits?

    nil
  end

  def send_messages
    send_message = Captain::Llm::AssistantChatService.new(
      @message.content,
      @context.conversation.id,
      @context.ai_agent.chat_flow_id
    ).generate_response

    return send_reply_failure(I18n.t('conversations.bot.failure')) unless send_message.success?

    @context.usage.increment_ai_responses
    Rails.logger.info("🤖 AI Response: #{send_message.body}")

    response = send_message.parsed_response
    message, is_handover = get_message_content(response)

    send_reply(message, is_handover: is_handover)
  end

  def send_reply(content, is_handover: false)
    message_content = is_handover ? handover_processing(content) : content

    message_created(message_content)
    send_log_reply(is_handover: is_handover)
  rescue StandardError => e
    Rails.logger.error("❌ Failed to save AI reply: #{e.message}")
  end

  def send_reply_failure(reason)
    Rails.logger.error("❌ Bot failure: #{reason}")
    send_reply(reason, is_handover: false)
  end

  def long_running_notify
    Rails.logger.info('🤖 Bot is running long time, notifying...')
    send_reply(I18n.t('conversations.bot.long_running_message'), is_handover: false)
  end

  def handover_processing(content)
    agent_available = find_available_agent

    @context.conversation.update!(assignee_id: agent_available.id) if agent_available
    agent_available ? content : I18n.t('conversations.bot.not_available_agent')
  end

  def send_log_reply(is_handover: false)
    if is_handover
      Rails.logger.info("🧑‍💼 Handover completed: Conversation #{@context.conversation.id} assigned to Agent!")
    else
      Rails.logger.info('🤖 Bot completed to reply message')
    end
  end

  def get_message_content(response)
    is_handover = response.dig('json', 'is_handover')
    message = if is_handover
                if response.dig('json', 'user_requested_human')
                  I18n.t('conversations.bot.requested_human_message')
                else
                  I18n.t('conversations.bot.escalation_message')
                end
              else
                response['text']
              end

    [message, is_handover]
  end

  def find_available_agent
    member_ids = InboxMember.where(inbox_id: @context.inbox_id).pluck(:user_id)
    return nil if member_ids.empty?

    agent_id = Conversation.least_loaded_agent(@context.inbox_id, member_ids)
    agent_id ||= member_ids.sample

    User.find_by(id: agent_id)
  end

  def message_created(content)
    attrs = {
      content: content,
      account_id: @context.account_id,
      inbox_id: @context.conversation.inbox_id,
      conversation_id: @context.conversation.id,
      message_type: 1,
      content_type: 0,
      status: 0,
      sender_type: 'AiAgent'
    }

    attrs[:sender_id] = @context.ai_agent&.id

    Message.create!(attrs)
  end
end
