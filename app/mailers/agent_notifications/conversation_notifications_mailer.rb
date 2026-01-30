class AgentNotifications::ConversationNotificationsMailer < ApplicationMailer
  def conversation_creation(conversation, agent, _user)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    recipients = if @account.suspended?
                   super_admin_emails(@account)
                 else
                   [@agent.email]
                 end
    
    return if recipients.blank?

    inbox_name = @conversation.inbox&.sanitized_name
    subject = "#{@agent.available_name}, A new conversation [ID - #{@conversation.display_id}] has been created in #{inbox_name}."
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def conversation_assignment(conversation, agent, _user)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    recipients = if @account.suspended?
                   super_admin_emails(@account)
                 else
                   [@agent.email]
                 end
    
    return if recipients.blank?

    subject = "#{@agent.available_name}, A new conversation [ID - #{@conversation.display_id}] has been assigned to you."
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def conversation_mention(conversation, agent, message)
    return unless smtp_config_set_or_development?

    @agent = agent
    @conversation = conversation
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    recipients = if @account.suspended?
                   super_admin_emails(@account)
                 else
                   [@agent.email]
                 end
    
    return if recipients.blank?

    @message = message
    subject = "#{@agent.available_name}, You have been mentioned in conversation [ID - #{@conversation.display_id}]"
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def assigned_conversation_new_message(conversation, agent, message)
    return unless smtp_config_set_or_development?
    
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    if @account.suspended?
      recipients = super_admin_emails(@account)
      return if recipients.blank?
    else
      # Don't spam with email notifications if agent is online
      return if ::OnlineStatusTracker.get_presence(message.account_id, 'User', agent.id)
      recipients = [agent.email]
    end

    @agent = agent
    @conversation = conversation
    subject = "#{@agent.available_name}, New message in your assigned conversation [ID - #{@conversation.display_id}]."
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  def participating_conversation_new_message(conversation, agent, message)
    return unless smtp_config_set_or_development?
    
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    if @account.suspended?
      recipients = super_admin_emails(@account)
      return if recipients.blank?
    else
      # Don't spam with email notifications if agent is online
      return if ::OnlineStatusTracker.get_presence(message.account_id, 'User', agent.id)
      recipients = [agent.email]
    end

    @agent = agent
    @conversation = conversation
    subject = "#{@agent.available_name}, New message in your participating conversation [ID - #{@conversation.display_id}]."
    @action_url = app_account_conversation_url(account_id: @conversation.account_id, id: @conversation.display_id)
    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  private

  def liquid_droppables
    super.merge({
                  user: @agent,
                  conversation: @conversation,
                  inbox: @conversation.inbox,
                  message: @message
                })
  end
end

AgentNotifications::ConversationNotificationsMailer.prepend_mod_with('AgentNotifications::ConversationNotificationsMailer')
