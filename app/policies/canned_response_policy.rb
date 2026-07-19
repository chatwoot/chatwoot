class CannedResponsePolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def show?
    return true if @account_user.administrator?
    return true if author?
    return true if @record.global? && @record.approved?

    false
  end

  def update?
    return true if @account_user.administrator?
    return false if @record.global?

    author?
  end

  def destroy?
    return true if @account_user.administrator?
    return false if @record.global?

    author?
  end

  def approve?
    @account_user.administrator?
  end

  def reject?
    @account_user.administrator?
  end

  private

  def author?
    @record.created_by_id == @account_user.user_id
  end
end
