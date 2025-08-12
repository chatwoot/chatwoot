# frozen_string_literal: true

class Enterprise::AssignmentV2::CapacityService
  def initialize(account_user)
    @account_user = account_user
    @account = account_user.account
  end

  def agent_has_capacity?(inbox = nil)
    return true unless capacity_policy_applicable?

    if inbox
      check_inbox_capacity(inbox)
    else
      check_overall_capacity
    end
  end

  def agent_capacity_for_inbox(inbox)
    return Float::INFINITY unless capacity_policy_applicable?

    policy = @account_user.agent_capacity_policy
    inbox_limit = policy.capacity_for_inbox(inbox)
    return Float::INFINITY unless inbox_limit

    current_count = current_conversations_count(inbox)
    [inbox_limit - current_count, 0].max
  end

  def agent_overall_capacity
    return Float::INFINITY unless capacity_policy_applicable?

    policy = @account_user.agent_capacity_policy
    overall_limit = policy.overall_capacity
    return Float::INFINITY if overall_limit == Float::INFINITY

    current_count = current_conversations_count
    [overall_limit - current_count, 0].max
  end

  def current_conversations_count(inbox = nil)
    scope = @account_user.user.conversations
                         .joins(:account)
                         .where(account: @account, status: :open)
    scope = scope.where(inbox: inbox) if inbox
    scope.count
  end

  private

  def capacity_policy_applicable?
    return false if @account_user.agent_capacity_policy.blank?

    @account_user.agent_capacity_policy.applicable_for_time?
  end

  def check_inbox_capacity(inbox)
    policy = @account_user.agent_capacity_policy
    inbox_limit = policy.capacity_for_inbox(inbox)

    return check_overall_capacity unless inbox_limit

    current_count = current_conversations_count(inbox)
    current_count < inbox_limit && check_overall_capacity
  end

  def check_overall_capacity
    policy = @account_user.agent_capacity_policy
    overall_limit = policy.overall_capacity

    return true if overall_limit == Float::INFINITY

    current_count = current_conversations_count
    current_count < overall_limit
  end
end
