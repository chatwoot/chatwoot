class ResponseSourcePolicy < ApplicationPolicy
  def parse?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end
end
