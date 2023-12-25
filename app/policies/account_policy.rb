class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def cache_keys?
    @account_user.administrator? || @account_user.agent?
  end

  def limits?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
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

  def get_ltd?
    account_user.administrator?
  end

  def get_ltd_details?
    account_user.administrator?
  end

  def stripe_checkout?
    @account_user.administrator?
  end

  def stripe_subscription?
    @account_user.administrator?
  end

  def usage_limits?
    @account_user.administrator?
  end
end
