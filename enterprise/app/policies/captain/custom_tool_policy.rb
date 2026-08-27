class Captain::CustomToolPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    @account_user.administrator?
  end

  def test?
    @account_user.administrator?
  end

  def preview_import?
    @account_user.administrator?
  end

  def import?
    @account_user.administrator?
  end

  def export?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
