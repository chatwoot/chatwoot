class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator?
  end

  def update_active_at?
    true
  end

  def billing_subscription?
    account_user.administrator? 
  end

  def start_billing_subscription?
    account_user.administrator? 
  end
end
