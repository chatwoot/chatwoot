class StorefrontLinkPolicy < ApplicationPolicy
  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def preview?
    @account_user.administrator? || @account_user.agent?
  end
end
