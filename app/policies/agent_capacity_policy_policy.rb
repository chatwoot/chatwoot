# frozen_string_literal: true

class AgentCapacityPolicyPolicy < ApplicationPolicy
  def index?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).index?
  end

  def show?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).show?
  end

  def create?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).create?
  end

  def update?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).update?
  end

  def destroy?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).destroy?
  end

  def set_inbox_limit?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).set_inbox_limit?
  end

  def remove_inbox_limit?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).remove_inbox_limit?
  end

  def assign_user?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).assign_user?
  end

  def remove_user?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).remove_user?
  end

  def agent_capacity?
    return false unless defined?(::Enterprise::AgentCapacityPolicyPolicy)

    ::Enterprise::AgentCapacityPolicyPolicy.new(@user_context, @record).agent_capacity?
  end
end
