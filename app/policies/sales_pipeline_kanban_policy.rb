class SalesPipelineKanbanPolicy < ApplicationPolicy
  def show?
    account_member?
  end

  private

  def account_member?
    user.account_users.exists?(account_id: record.account_id)
  end
end