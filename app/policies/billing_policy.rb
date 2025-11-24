class BillingPolicy < ApplicationPolicy
  def credit_grants?
    @account_user.administrator?
  end

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

  def cancel_subscription?
    @account_user.administrator?
  end

  def change_pricing_plan?
    @account_user.administrator?
  end
end
