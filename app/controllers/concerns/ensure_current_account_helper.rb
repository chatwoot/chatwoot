module EnsureCurrentAccountHelper
  private

  def current_account
    @current_account ||= ensure_current_account
    Current.account = @current_account
  end

  def ensure_current_account
    account = Account.find(params[:account_id])
    if current_user
      account_accessible_for_user?(account)
    elsif @resource.is_a?(AgentBot)
      account_accessible_for_bot?(account)
    end
    account
  end

  def account_accessible_for_user?(account)
    @current_account_user = account.account_users.find_by(user_id: current_user.id)
    Current.account_user = @current_account_user
    render_unauthorized('You are not authorized to access this account') unless @current_account_user
  end

  def account_accessible_for_bot?(account)
    render_unauthorized('You are not authorized to access this account') unless @resource.agent_bot_inboxes.find_by(account_id: account.id)
  end
end
