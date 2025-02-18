class LabelPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator? || can_manage_labels?
  end

  def destroy?
    @account_user.administrator?
  end

  private

  def can_manage_labels?
    @account.custom_attributes['show_label_to_agent']
  end
end
