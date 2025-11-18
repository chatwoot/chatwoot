class SalesPipelinePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    account_member?
  end

  def create?
    administrator?
  end

  def update?
    administrator?
  end

  def destroy?
    administrator?
  end

  private

  def administrator?
    user.account_users.exists?(role: :administrator)
  end

  def account_member?
    user.account_users.exists?(account_id: record.account_id)
  end
end