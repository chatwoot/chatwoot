class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = current_account.conversations.find_by!(display_id: params[:id])
    reject unless conversation_accessible?(conversation)

    stream_for conversation
  end

  private

  def conversation_accessible?(conversation)
    return true unless restricted_agent?

    Conversations::AgentAccessService.new(
      conversation: conversation,
      user: current_user,
      account: current_account,
      account_user: account_user
    ).allowed?
  end

  def restricted_agent?
    Conversations::AgentAccessService.restricted_agent?(account_user)
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: current_account.id, user_id: current_user.id)
  end

  def current_user
    @current_user ||= User.find_by!(id: params[:user_id], pubsub_token: params[:pubsub_token])
  end

  def current_account
    @current_account ||= current_user.accounts.find(params[:account_id])
  end
end
