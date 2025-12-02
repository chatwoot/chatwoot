module Enterprise::AgentNotifications::ConversationNotificationsMailer
  def sla_missed_first_response(conversation, agent, sla_policy)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @sla_policy = sla_policy
    subject = "Conversation [ID - #{@conversation.display_id}] missed SLA for first response"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: subject) and return
  end

  def sla_missed_next_response(conversation, agent, sla_policy)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @sla_policy = sla_policy
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: "Conversation [ID - #{@conversation.display_id}] missed SLA for next response") and return
  end

  def sla_missed_resolution(conversation, agent, sla_policy)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @sla_policy = sla_policy
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: @agent.email, subject: "Conversation [ID - #{@conversation.display_id}] missed SLA for resolution time") and return
  end

  def liquid_droppables
    super.merge({
                  sla_policy: @sla_policy
                })
  end
end
