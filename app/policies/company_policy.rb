# Restore the Companies feature (dropped with enterprise edition).
# Agents can view/list; only administrators manage companies.
class CompanyPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def search?
    true
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def destroy_custom_attributes?
    @account_user.administrator?
  end

  def avatar?
    @account_user.administrator?
  end
end

CompanyPolicy.prepend_mod_with('CompanyPolicy')
