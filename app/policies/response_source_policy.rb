class ResponseSourcePolicy < ApplicationPolicy
  def create?
    @account_user.administrator?
  end
end
