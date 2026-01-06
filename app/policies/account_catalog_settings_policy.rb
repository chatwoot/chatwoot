class AccountCatalogSettingsPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end
end
