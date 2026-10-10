# Run in a disposable *_concurrency test database with its own Redis database.
abort 'Use an isolated concurrency test database' unless Rails.env.test? && ENV.fetch('POSTGRES_DATABASE').end_with?('_concurrency')
require 'factory_bot'
ActiveJob::Base.queue_adapter = :test

account = FactoryBot.create(:account)
account.enable_features!('assignment_v2', 'advanced_assignment')
role = FactoryBot.create(:custom_role, account: account)
agent = FactoryBot.create(:user, account: account)
inbox = FactoryBot.create(:inbox, account: account, enable_auto_assignment: true)
FactoryBot.create(:inbox_member, inbox: inbox, user: agent)
policy = FactoryBot.create(:assignment_policy, account: account, assignment_order: :balanced, eligible_custom_role: role,
                                               fair_distribution_limit: 5, fair_distribution_window: 3600)
FactoryBot.create(:inbox_assignment_policy, inbox: inbox, assignment_policy: policy)
capacity = FactoryBot.create(:agent_capacity_policy, account: account)
limit = FactoryBot.create(:inbox_capacity_limit, inbox: inbox, agent_capacity_policy: capacity, conversation_limit: 100)
agent.account_users.find_by!(account: account).update!(custom_role: role, agent_capacity_policy: capacity)
OnlineStatusTracker.update_presence(account.id, 'User', agent.id)
OnlineStatusTracker.set_status(account.id, agent.id, 'online')
FactoryBot.create_list(:conversation, 99, account: account, inbox: inbox, assignee: agent)
waiting = FactoryBot.create_list(:conversation, 2, account: account, inbox: inbox, assignee: nil)

barrier = Queue.new
workers = waiting.map do |conversation|
  Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      barrier.pop
      AutoAssignment::AssignmentService.new(inbox: Inbox.find(inbox.id)).send(:perform_for_conversation, Conversation.find(conversation.id))
    end
  end
end
workers.length.times { barrier << true }
results = workers.map(&:value)
raise 'Concurrent assignment exceeded capacity' unless results.count(true) == 1 && inbox.conversations.open.where(assignee: agent).count == 100

limit.update!(conversation_limit: 200)
service = AutoAssignment::AssignmentService.new(inbox: inbox)
3.times do
  conversation = FactoryBot.create(:conversation, account: account, inbox: inbox, assignee: nil)
  raise 'Sequential assignment failed' unless service.send(:perform_for_conversation, conversation)
end
waiting = FactoryBot.create_list(:conversation, 2, account: account, inbox: inbox, assignee: nil)
workers = waiting.map do |conversation|
  Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      barrier.pop
      AutoAssignment::AssignmentService.new(inbox: Inbox.find(inbox.id)).send(:perform_for_conversation, Conversation.find(conversation.id))
    end
  end
end
workers.length.times { barrier << true }
results = workers.map(&:value)
count = AutoAssignment::RateLimiter.new(inbox: inbox, agent: agent).current_count
raise 'Concurrent assignment exceeded the hourly limit' unless results.count(true) == 1 && count == 5

puts({ capacity_race: 'passed', hourly_rate_race: 'passed', rate_count: count }.to_json)
