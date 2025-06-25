class Captain::AssistantPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def playground?
    true
  end

  def upload_pdf?
    @account_user.administrator?
  end
end
