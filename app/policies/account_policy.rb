class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def cache_keys?
    @account_user.administrator? || @account_user.agent?
  end

  def limits?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    # CommMate: Allow administrators or users with settings_account_manage permission
    @account_user.administrator? || has_account_manage_permission?
  end

  def update_active_at?
    true
  end

  def subscription?
    @account_user.administrator?
  end

  def checkout?
    @account_user.administrator?
  end

  def toggle_deletion?
    @account_user.administrator?
  end

  def topup_checkout?
    @account_user.administrator?
  end

  private

  # CommMate: Check if user has settings_account_manage permission
  def has_account_manage_permission?
    @account_user.permissions.include?('settings_account_manage')
  end
end
