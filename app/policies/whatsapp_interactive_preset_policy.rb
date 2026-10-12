class WhatsappInteractivePresetPolicy < ApplicationPolicy
  def index?
    account_member?
  end

  def show?
    account_member? && record.account_id == account.id
  end

  def create?
    account_member?
  end

  def update?
    show? && record.created_by_id == user.id
  end

  def destroy?
    show? && account_user.administrator?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account_id: account.id)
    end
  end

  private

  def account_member?
    account_user.present? && (account_user.agent? || account_user.administrator?)
  end
end
