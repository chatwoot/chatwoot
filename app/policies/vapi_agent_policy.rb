class VapiAgentPolicy < ApplicationPolicy
  def index?
    return true if @user.is_a?(SuperAdmin)

    @account_user&.administrator? || @account_user&.owner?
  end

  def show?
    return true if @user.is_a?(SuperAdmin)

    @account_user&.administrator? || @account_user&.owner?
  end

  def create?
    return true if @user.is_a?(SuperAdmin)

    @account_user&.administrator? || @account_user&.owner?
  end

  def update?
    return true if @user.is_a?(SuperAdmin)

    @account_user&.administrator? || @account_user&.owner?
  end

  def destroy?
    return true if @user.is_a?(SuperAdmin)

    @account_user&.administrator? || @account_user&.owner?
  end

  def sync_agents?
    return true if @user.is_a?(SuperAdmin)

    @account_user&.administrator? || @account_user&.owner?
  end
end

