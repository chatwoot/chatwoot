class LeaveRecordPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || owned_by_user?
  end

  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    return false unless @record.pending?

    @account_user.administrator? || owned_by_user?
  end

  def destroy?
    return false unless @record.can_be_cancelled?

    @account_user.administrator? || owned_by_user?
  end

  def approve?
    @account_user.administrator?
  end

  def reject?
    @account_user.administrator?
  end

  class Scope
    attr_reader :user_context, :user, :scope, :account, :account_user

    def initialize(user_context, scope)
      @user_context = user_context
      @user = user_context[:user]
      @account = user_context[:account]
      @account_user = user_context[:account_user]
      @scope = scope
    end

    def resolve
      if @account_user.administrator?
        scope.includes(:user, :approver)
      else
        scope.where(user: @user).includes(:user, :approver)
      end
    end
  end

  private

  def owned_by_user?
    @record&.user_id == @account_user.user_id
  end
end
