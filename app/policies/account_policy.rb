class AccountPolicy < ApplicationPolicy
  def show?
    # FIXME : temporary hack to transition over to multiple accounts per user
    # We should be fetching the current account user relationship here.
    @user.administrator?
  end

  def update?
    # FIXME : temporary hack to transition over to multiple accounts per user
    # We should be fetching the current account user relationship here.
    @user.administrator?
  end
end
