# frozen_string_literal: true

class Saas::AiAgentInboxPolicy < ApplicationPolicy
  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
