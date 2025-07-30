# frozen_string_literal: true

module Enterprise
  class AgentCapacityPolicyPolicy < ApplicationPolicy
    def index?
      @account_user.administrator?
    end

    def show?
      @account_user.administrator?
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

    def set_inbox_limit?
      @account_user.administrator?
    end

    def remove_inbox_limit?
      @account_user.administrator?
    end

    def assign_user?
      @account_user.administrator?
    end

    def remove_user?
      @account_user.administrator?
    end

    def agent_capacity?
      @account_user.administrator? || @account_user.agent?
    end
  end
end