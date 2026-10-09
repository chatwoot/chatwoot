require 'rails_helper'

RSpec.describe AutoAssignment::TeamAssignmentRetryJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:team) { create(:team, account: account, allow_auto_assign: true) }
  # auto_offline: false keeps the agent in the online set without a websocket presence
  let(:agent) { create(:user, account: account, role: :agent, auto_offline: false) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, team: team) }

  before do
    # Create the conversation before the memberships so the initial team
    # assignment (on team_id change) finds nobody, as when the team is offline.
    conversation
    create(:team_member, team: team, user: agent)
    create(:inbox_member, inbox: inbox, user: agent)
  end

  after { Redis::Alfred.delete(format(Redis::Alfred::TEAM_ASSIGNMENT_DEBOUNCE_KEY, account_id: account.id)) }

  describe '#perform' do
    it 'assigns a waiting team conversation to an online team member' do
      expect(conversation.reload.assignee).to be_nil

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to eq(agent)
      activity = { account_id: account.id, inbox_id: inbox.id, message_type: :activity,
                   content: "Assigned to #{agent.name} by Automation System" }
      expect(Conversations::ActivityMessageJob).to have_been_enqueued.with(conversation, activity)
    end

    it 'leaves the conversation alone when no team member is online' do
      agent.account_users.find_by(account: account).update!(availability: :offline)

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'ignores conversations of teams without auto assign' do
      team.update!(allow_auto_assign: false)

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'ignores conversations that lost their team' do
      conversation.update!(team: nil)

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'ignores conversations that are not open' do
      conversation.update!(status: :pending)

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'ignores conversations with no activity for a week' do
      conversation.update_columns(last_activity_at: 8.days.ago) # rubocop:disable Rails/SkipsModelValidations

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'only considers team members who are inbox members' do
      inbox.inbox_members.find_by(user: agent).destroy!

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'keeps an existing assignee' do
      other = create(:user, account: account, role: :agent)
      conversation.update!(assignee: other)

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to eq(other)
    end

    it 'queues another pass when a full pass made progress' do
      stub_const('AutoAssignment::TeamAssignmentRetryJob::BATCH_LIMIT', 1)
      agent.account_users.find_by(account: account).update!(availability: :offline)
      create(:conversation, account: account, inbox: inbox, team: team)
      agent.account_users.find_by(account: account).update!(availability: :online)
      # Going online enqueued a run and set the debounce key; clear both so only the job's own re-enqueue is observed.
      clear_enqueued_jobs
      Redis::Alfred.delete(format(Redis::Alfred::TEAM_ASSIGNMENT_DEBOUNCE_KEY, account_id: account.id))

      described_class.perform_now(account: account)

      expect(described_class).to have_been_enqueued.once.with(account: account)
    end

    it 'hands inboxes on Assignment V2 bulk assignment to the AssignmentJob' do
      account.enable_features('assignment_v2')
      account.save!
      inbox.update!(enable_auto_assignment: true)
      allow(AutoAssignment::AssignmentJob).to receive(:enqueue_for_inbox)

      described_class.perform_now(account: account)

      expect(conversation.reload.assignee).to be_nil
      expect(AutoAssignment::AssignmentJob).to have_received(:enqueue_for_inbox).with(inbox.id)
    end
  end

  describe '.enqueue_for_account' do
    it 'enqueues one delayed run per account per coalesce window' do
      described_class.enqueue_for_account(account)
      described_class.enqueue_for_account(account)

      expect(described_class).to have_been_enqueued.once.with(account: account)
    end
  end
end
