class WhatsappTopupRequestPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  class Scope < Scope
    def resolve
      return scope.where(account_id: account.id) if account_user.administrator?

      scope.none
    end
  end
end
