require 'factory_bot_rails'

class AgentNotifications::ConversationNotificationsMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def conversation_creation
    account = create(:account, locale: params[:locale] || 'en')
    agent = create(:user, account: account)
    conversation = create(:conversation, assignee: agent, account: account)
    create(:message, conversation: conversation, account: account)
    AgentNotifications::ConversationNotificationsMailer.with({}).conversation_creation(
      conversation, agent, agent
    )
  end

  def conversation_assignment
    account = create(:account, locale: params[:locale] || 'en')
    agent = create(:user, account: account)
    conversation = create(:conversation, assignee: agent, account: account)
    AgentNotifications::ConversationNotificationsMailer.with({}).conversation_assignment(
      conversation, agent, agent
    )
  end

  def conversation_mention
    account = create(:account, locale: params[:locale] || 'en')
    agent = create(:user, account: account)
    conversation = create(:conversation, assignee: agent, account: account)
    another_agent = create(:user, account: account)
    message = create(:message, conversation: conversation, account: account, sender: another_agent)
    AgentNotifications::ConversationNotificationsMailer.with({}).conversation_mention(
      conversation, agent, message
    )
  end

  def assigned_conversation_new_message
    account = create(:account, locale: params[:locale] || 'en')
    agent = create(:user, account: account)
    conversation = create(:conversation, assignee: agent, account: account)
    message = create(:message, conversation: conversation, account: account)
    AgentNotifications::ConversationNotificationsMailer.with({}).assigned_conversation_new_message(
      conversation, agent, message
    )
  end

  def participating_conversation_new_message
    account = create(:account, locale: params[:locale] || 'en')
    agent = create(:user, account: account)
    conversation = create(:conversation, assignee: agent, account: account)
    message = create(:conversation, assignee: agent, account: account)
    AgentNotifications::ConversationNotificationsMailer.with({}).participating_conversation_new_message(
      conversation, agent, message
    )
  end
end
