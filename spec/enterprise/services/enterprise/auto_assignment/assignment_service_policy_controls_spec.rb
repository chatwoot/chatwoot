require 'rails_helper'

RSpec.describe AutoAssignment::AssignmentService do
  let(:account) { create(:account) }
  let(:role) { create(:custom_role, account: account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true, timezone: 'America/Sao_Paulo', working_hours_enabled: true) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:policy) do
    create(:assignment_policy, account: account, assignment_order: :balanced, eligible_custom_role: role,
                               business_hours_only: true, conversation_priority: :latest_customer_message,
                               fair_distribution_limit: 5, fair_distribution_window: 3600)
  end
  let(:service) { described_class.new(inbox: inbox) }

  before do
    travel_to Time.zone.parse('2026-10-12 15:00:00 UTC')
    account.enable_features!('assignment_v2', 'advanced_assignment')
    create(:inbox_assignment_policy, inbox: inbox, assignment_policy: policy)
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: manager)
    agent.account_users.find_by!(account: account).update!(custom_role: role)
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                               .and_return(agent.id.to_s => 'online', manager.id.to_s => 'online')
  end

  it 'assigns only eligible online sellers and preserves explicit manual assignments' do
    conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)
    manual = create(:conversation, account: account, inbox: inbox, assignee: manager)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(agent.id)
    expect(manual.reload.assignee_id).to eq(manager.id)

    waiting = create(:conversation, account: account, inbox: inbox, assignee: nil)
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                               .and_return(agent.id.to_s => 'offline', manager.id.to_s => 'online')
    expect(service.perform_bulk_assignment).to eq(0)
    expect(waiting.reload.assignee_id).to be_nil
  end

  it 'uses inbox Sunday hours and leaves conversations waiting after closing' do
    inbox.working_hours.find_by!(day_of_week: 0).update!(closed_all_day: false, open_hour: 10, open_minutes: 0, close_hour: 18, close_minutes: 0)
    travel_to Time.zone.parse('2026-10-11 12:59:00 UTC')
    conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)
    expect(service.perform_bulk_assignment).to eq(0)
    travel_to Time.zone.parse('2026-10-11 13:00:00 UTC')
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(agent.id)
    travel_to Time.zone.parse('2026-10-11 21:01:00 UTC')
    create(:conversation, account: account, inbox: inbox, assignee: nil)
    expect(service.perform_bulk_assignment).to eq(0)
  end

  it 'prioritizes the last customer message, ignoring newer notes and agent replies' do
    older = create(:conversation, account: account, inbox: inbox, assignee: nil, created_at: 2.days.ago)
    newer = create(:conversation, account: account, inbox: inbox, assignee: nil, created_at: 1.day.ago)
    create(:message, account: account, conversation: newer, message_type: :incoming, created_at: 1.hour.ago)
    create(:message, account: account, conversation: older, message_type: :incoming, created_at: 2.minutes.ago)
    create(:message, account: account, conversation: newer, message_type: :outgoing, private: true)
    create(:message, account: account, conversation: newer, message_type: :outgoing)

    expect(service.perform_bulk_assignment(limit: 1)).to eq(1)
    expect(older.reload.assignee_id).to eq(agent.id)
    expect(newer.reload.assignee_id).to be_nil
  end

  it 'uses creation time for conversations without an incoming message' do
    older = create(:conversation, account: account, inbox: inbox, assignee: nil, created_at: 1.hour.ago)
    latest = create(:conversation, account: account, inbox: inbox, assignee: nil)
    expect(service.perform_bulk_assignment(limit: 1)).to eq(1)
    expect(latest.reload.assignee_id).to eq(agent.id)
    expect(older.reload.assignee_id).to be_nil
  end

  it 'does not bypass the policy when assigning a team' do
    team = create(:team, account: account)
    create(:team_member, team: team, user: manager)
    conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)
    conversation.update!(team: team)
    expect(conversation.reload.assignee_id).to be_nil
    expect(service.perform_bulk_assignment).to eq(0)
    create(:team_member, team: team, user: agent)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(conversation.reload.assignee_id).to eq(agent.id)
  end

  it 'stops at 100 open conversations without moving existing assignments' do
    capacity = create(:agent_capacity_policy, account: account)
    create(:inbox_capacity_limit, inbox: inbox, agent_capacity_policy: capacity, conversation_limit: 100)
    agent.account_users.find_by!(account: account).update!(agent_capacity_policy: capacity)
    create_list(:conversation, 99, account: account, inbox: inbox, assignee: agent, status: :open)
    create_list(:conversation, 2, account: account, inbox: inbox, assignee: nil)
    expect(service.perform_bulk_assignment).to eq(1)
    expect(inbox.conversations.open.where(assignee: agent).count).to eq(100)
    expect(inbox.conversations.unassigned.count).to eq(1)
  end

  it 'assigns at most five conversations per hour and resumes when the window expires' do
    create_list(:conversation, 6, account: account, inbox: inbox, assignee: nil)
    expect(service.perform_bulk_assignment).to eq(5)
    expect(service.perform_bulk_assignment).to eq(0)
    travel 1.hour + 1.second
    expect(service.perform_bulk_assignment).to eq(1)
  end
end
