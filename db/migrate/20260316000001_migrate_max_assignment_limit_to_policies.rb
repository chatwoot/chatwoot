class MigrateMaxAssignmentLimitToPolicies < ActiveRecord::Migration[7.1]
  # Ruby's max for a 32-bit signed integer, matching PostgreSQL's integer column limit
  INT_MAX = (2**31) - 1

  def up
    Account.find_each do |account|
      migrate_account(account)
    end
  end

  def down
    AgentCapacityPolicy.where(name: 'Auto (Migrated)').destroy_all
  end

  private

  def migrate_account(account)
    inboxes_with_limit = account.inboxes
                                .where("auto_assignment_config->>'max_assignment_limit' ~ '^[0-9]+$'")
                                .where("(auto_assignment_config->>'max_assignment_limit')::numeric > 0")

    return if inboxes_with_limit.empty?

    ActiveRecord::Base.transaction do
      policy = AgentCapacityPolicy.find_or_create_by!(account: account, name: 'Auto (Migrated)') do |p|
        p.description = 'Migrated from max_assignment_limit on inbox auto_assignment_config'
      end

      create_inbox_limits(policy, inboxes_with_limit)
      assign_policy_to_inbox_members(account, policy, inboxes_with_limit)
    end
  end

  def create_inbox_limits(policy, inboxes)
    inboxes.each do |inbox|
      next if InboxCapacityLimit.exists?(agent_capacity_policy_id: policy.id, inbox_id: inbox.id)

      limit = [inbox.auto_assignment_config['max_assignment_limit'].to_i, INT_MAX].min

      InboxCapacityLimit.create!(
        agent_capacity_policy: policy,
        inbox: inbox,
        conversation_limit: limit
      )
    end
  end

  def assign_policy_to_inbox_members(account, policy, inboxes)
    member_user_ids = InboxMember.where(inbox_id: inboxes.select(:id)).distinct.pluck(:user_id)

    account.account_users
           .where(user_id: member_user_ids, agent_capacity_policy_id: nil)
           .find_each { |account_user| account_user.update!(agent_capacity_policy_id: policy.id) }
  end
end
