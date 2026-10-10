# Run with rails runner; preview is the default. See docs/sales-assignment-runbook.md.
account = Account.find(ENV.fetch('ACCOUNT_ID'))
inbox = account.inboxes.find(ENV.fetch('INBOX_ID'))
role = account.custom_roles.find(ENV.fetch('CUSTOM_ROLE_ID'))
policy_name = ENV.fetch('POLICY_NAME')
members = account.account_users.where(custom_role: role, user_id: inbox.members.select(:id))
raise 'No eligible sellers in the inbox' if members.empty?

capacity = account.agent_capacity_policies.find_or_initialize_by(name: policy_name)
other_capacity = members.where.not(agent_capacity_policy_id: nil).where.not(agent_capacity_policy_id: capacity.id)
raise 'An eligible seller already has another capacity policy; reconcile before applying' if other_capacity.exists?

puts({ account_id: account.id, inbox_id: inbox.id, custom_role_id: role.id, sellers: members.count,
       apply: ENV['APPLY'] == 'true', open_by_seller: inbox.conversations.open.where(assignee_id: members.select(:user_id))
                                                       .group(:assignee_id).count }.to_json)

if ENV['APPLY'] == 'true'
  account.with_lock do
    policy = account.assignment_policies.find_or_initialize_by(name: policy_name)
    policy.update!(assignment_order: :balanced, conversation_priority: :latest_customer_message, business_hours_only: true,
                   eligible_custom_role: role, fair_distribution_limit: 5, fair_distribution_window: 3600,
                   exclude_older_than_hours: 168, enabled: true)
    capacity.save!
    limit = capacity.inbox_capacity_limits.find_or_initialize_by(inbox: inbox)
    limit.update!(conversation_limit: 100)
    members.each { |member| member.update!(agent_capacity_policy: capacity) }
    link = inbox.inbox_assignment_policy || inbox.build_inbox_assignment_policy
    link.update!(assignment_policy: policy)
    inbox.update!(enable_auto_assignment: true, working_hours_enabled: true, timezone: 'America/Sao_Paulo')
    inbox.working_hours.each do |day|
      weekend = day.day_of_week.in?([0, 6])
      day.update!(closed_all_day: false, open_all_day: false, open_hour: weekend ? 10 : 9, open_minutes: 0,
                  close_hour: weekend ? 18 : 19, close_minutes: 0)
    end
    logout = { 'enabled' => true, 'inbox_id' => inbox.id, 'custom_role_id' => role.id,
               'time' => '20:00', 'timezone' => 'America/Sao_Paulo' }
    previous_logout = account.settings['daily_agent_logout'] || {}
    if previous_logout['last_completed_on'].present? && previous_logout.except('last_completed_on') == logout
      logout['last_completed_on'] =
        previous_logout['last_completed_on']
    end
    account.update!(settings: account.settings.merge('daily_agent_logout' => logout))
  end

  inbox.reload
  raise 'Assignment policy was not persisted' unless inbox.assignment_policy.latest_customer_message? && inbox.assignment_policy.business_hours_only?
  raise 'Capacity policy was not applied to every seller' unless members.reload.all? { |member| member.agent_capacity_policy_id == capacity.id }
  raise 'Unrelated Captain controls changed' unless account.reload.settings.values_at('auto_fix_grammar', 'auto_reply_suggestions') == [false, true]

  puts({ applied: true, assignment_policy_id: inbox.assignment_policy.id, capacity_policy_id: capacity.id,
         sellers: members.count, logout: account.settings.fetch('daily_agent_logout') }.to_json)
end
