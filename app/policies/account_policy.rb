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

  def toggle_deletion?
    @account_user.administrator?
  end

  def v2_pricing_plans?
    @account_user.administrator?
  end

  def v2_topup_options?
    @account_user.administrator?
  end

  def v2_topup?
    @account_user.administrator?
  end

  def v2_subscribe?
    @account_user.administrator?
  end

  def cancel_subscription?
    @account_user.administrator?
  end

  def credit_grants?
    @account_user.administrator?
  end

  def change_pricing_plan?
    @account_user.administrator?
  end

  # V2 Billing API actions
  def pricing_plans?
    @account_user.administrator?
  end

  def topup_options?
    @account_user.administrator?
  end

  def topup?
    @account_user.administrator?
  end

  def subscribe?
    @account_user.administrator?
  end
end
