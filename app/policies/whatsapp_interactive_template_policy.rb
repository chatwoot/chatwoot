class WhatsappInteractiveTemplatePolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def destroy?
    @account_user.administrator? || @account_user.agent?
  end

  def publish_header?
    create?
  end
end
