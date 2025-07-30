# frozen_string_literal: true

class LeavePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    # Users can view their own leaves or admins can view all
    record.account_user.user_id == user.id || @account_user.administrator?
  end

  def create?
    # Users can create their own leave requests
    record.account_user.user_id == user.id
  end

  def update?
    # Users can update their own pending/rejected leaves
    # Admins can update any leave
    if @account_user.administrator?
      true
    else
      record.account_user.user_id == user.id && record.pending?
    end
  end

  def destroy?
    # Users can delete their own pending leaves
    # Admins can delete any non-approved leave
    if @account_user.administrator?
      !record.approved?
    else
      record.account_user.user_id == user.id && record.pending?
    end
  end

  def approve?
    # Only admins can approve/reject leaves
    @account_user.administrator? && record.pending?
  end

  def reject?
    approve?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if @account_user.administrator?
        # Admins can see all leaves in the account
        scope.where(account: account)
      else
        # Regular users can only see their own leaves
        scope.joins(:account_user).where(account: account, account_users: { user_id: user.id })
      end
    end
  end
end