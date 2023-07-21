class ResponseSourcePolicy < ApplicationPolicy
  def parse?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def add_document?
    @account_user.administrator?
  end

  def remove_document?
    @account_user.administrator?
  end
end
