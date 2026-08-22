module EnsureCurrentAccountHelper
  private

  def current_account
    @current_account ||= ensure_current_account
    Current.account = @current_account
  end

  def ensure_current_account
    account = Account.find(params[:account_id])
    render_unauthorized('Account is suspended') and return unless account.active?

    if current_user
      account_accessible_for_user?(account)
    else
      render_unauthorized(I18n.t('errors.account.not_authorized'))
    end
    account
  end

  def account_accessible_for_user?(account)
    @current_account_user = account.account_users.find_by(user_id: current_user.id)
    Current.account_user = @current_account_user
    render_unauthorized(I18n.t('errors.account.not_authorized')) unless @current_account_user
  end
end
