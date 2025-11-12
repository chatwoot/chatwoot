class PaymentLinkPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent? || @account_user.custom_role&.permissions&.include?('contact_manage')
  end

  def search?
    true
  end

  def filter?
    true
  end
end
