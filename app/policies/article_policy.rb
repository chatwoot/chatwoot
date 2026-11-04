class ArticlePolicy < ApplicationPolicy
  def index?
    @account.users.include?(@user)
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def edit?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def reorder?
    @account_user.administrator?
  end

  def preview_token?
    show?
  end
end

ArticlePolicy.prepend_mod_with('ArticlePolicy')
