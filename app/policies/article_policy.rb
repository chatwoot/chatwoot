class ArticlePolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account.users.include?(@user)
  end

  def update?
    @account_user.administrator? || portal_member?
  end

  def show?
    @account_user.administrator? || portal_member?
  end

  def edit?
    @account_user.administrator? || portal_member?
  end

  def create?
    @account_user.administrator? || portal_member?
  end

  def destroy?
    @account_user.administrator? || portal_member?
  end

  def reorder?
    @account_user.administrator? || portal_member?
  end

  private

  def portal_member?
    @record.first.portal.members.include?(@user)
  end
end

ArticlePolicy.prepend_mod_with('Enterprise::ArticlePolicy')
