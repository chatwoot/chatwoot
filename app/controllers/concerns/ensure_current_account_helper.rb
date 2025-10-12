module EnsureCurrentAccountHelper
  private

  def current_account
    @current_account ||= ensure_current_account
    Current.account = @current_account
  end

  def ensure_current_account
    account = Account.find(params[:account_id])
    render_unauthorized('Account is suspended') and return unless account.active?

    acting_user = current_user || Current.user

    case acting_user
    when User
      account_accessible_for_user?(account, acting_user)
    when AgentBot
      account_accessible_for_bot?(account, acting_user)
    end
    account
  end

  def account_accessible_for_user?(account, user)
    @current_account_user = account.account_users.find_by(user_id: user.id)
    Current.account_user = @current_account_user
    render_unauthorized('You are not authorized to access this account') unless @current_account_user
  end

  def account_accessible_for_bot?(account, bot)
    render_unauthorized('Bot is not authorized to access this account') unless bot.agent_bot_inboxes.find_by(account_id: account.id)
  end
end
