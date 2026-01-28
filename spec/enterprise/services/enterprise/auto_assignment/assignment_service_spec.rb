require 'rails_helper'

RSpec.describe Enterprise::AutoAssignment::AssignmentService, type: :service do
  let(:account) { create(:account) }
  let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent1) { create(:user, account: account, name: 'Agent 1') }
  let(:agent2) { create(:user, account: account, name: 'Agent 2') }
  let(:assignment_service) { AutoAssignment::AssignmentService.new(inbox: inbox) }

  before do
    # Create inbox members
    create(:inbox_member, inbox: inbox, user: agent1)
    create(:inbox_member, inbox: inbox, user: agent2)

    # Link inbox to assignment policy
    create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)

    # Enable assignment_v2 (base) and advanced_assignment (premium) features
    account.enable_features('assignment_v2')
    account.save!

    # Set agents as online
    OnlineStatusTracker.update_presence(account.id, 'User', agent1.id)
    OnlineStatusTracker.set_status(account.id, agent1.id, 'online')
    OnlineStatusTracker.update_presence(account.id, 'User', agent2.id)
    OnlineStatusTracker.set_status(account.id, agent2.id, 'online')
  end

  describe 'exclusion rules' do
    let(:capacity_policy) { create(:agent_capacity_policy, account: account) }
    let(:label1) { create(:label, account: account, title: 'high-priority') }
    let(:label2) { create(:label, account: account, title: 'vip') }

    before do
      create(:inbox_capacity_limit, inbox: inbox, agent_capacity_policy: capacity_policy, conversation_limit: 10)
      inbox.enable_auto_assignment = true
      inbox.save!
    end

    context 'when excluding conversations by label' do
      let!(:conversation_with_label) { create(:conversation, inbox: inbox, assignee: nil) }
      let!(:conversation_without_label) { create(:conversation, inbox: inbox, assignee: nil) }

      before do
        conversation_with_label.update_labels([label1.title])

        capacity_policy.update!(exclusion_rules: {
                                  'excluded_labels' => [label1.title]
                                })
      end

      it 'excludes conversations with specified labels' do
        # First check conversations are unassigned
        expect(conversation_with_label.assignee).to be_nil
        expect(conversation_without_label.assignee).to be_nil

        # Run bulk assignment
        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        # Only the conversation without label should be assigned
        expect(assigned_count).to eq(1)
        expect(conversation_with_label.reload.assignee).to be_nil
        expect(conversation_without_label.reload.assignee).to be_present
      end

      it 'handles bulk assignment correctly' do
        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        # Only 1 conversation should be assigned (the one without label)
        expect(assigned_count).to eq(1)
        expect(conversation_with_label.reload.assignee).to be_nil
        expect(conversation_without_label.reload.assignee).to be_present
      end

      it 'excludes conversations with multiple labels' do
        conversation_without_label.update_labels([label2.title])

        capacity_policy.update!(exclusion_rules: {
                                  'excluded_labels' => [label1.title, label2.title]
                                })

        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        # Both conversations should be excluded
        expect(assigned_count).to eq(0)
        expect(conversation_with_label.reload.assignee).to be_nil
        expect(conversation_without_label.reload.assignee).to be_nil
      end
    end

    context 'when excluding conversations by age' do
      let!(:old_conversation) { create(:conversation, inbox: inbox, assignee: nil, created_at: 25.hours.ago) }
      let!(:recent_conversation) { create(:conversation, inbox: inbox, assignee: nil, created_at: 1.hour.ago) }

      before do
        capacity_policy.update!(exclusion_rules: {
                                  'exclude_older_than_hours' => 24
                                })
      end

      it 'excludes conversations older than specified hours' do
        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        # Only recent conversation should be assigned
        expect(assigned_count).to eq(1)
        expect(old_conversation.reload.assignee).to be_nil
        expect(recent_conversation.reload.assignee).to be_present
      end

      it 'handles different time thresholds' do
        capacity_policy.update!(exclusion_rules: {
                                  'exclude_older_than_hours' => 2
                                })

        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        # Only conversation created within 2 hours should be assigned
        expect(assigned_count).to eq(1)
        expect(recent_conversation.reload.assignee).to be_present
      end
    end

    context 'when combining exclusion rules' do
      it 'applies both exclusion rules' do
        # Create conversations
        old_conversation_with_label = create(:conversation, inbox: inbox, assignee: nil, created_at: 25.hours.ago)
        old_conversation_without_label = create(:conversation, inbox: inbox, assignee: nil, created_at: 25.hours.ago)
        recent_conversation_with_label = create(:conversation, inbox: inbox, assignee: nil, created_at: 1.hour.ago)
        recent_conversation_without_label = create(:conversation, inbox: inbox, assignee: nil, created_at: 1.hour.ago)

        # Add labels
        old_conversation_with_label.update_labels([label1.title])
        recent_conversation_with_label.update_labels([label1.title])

        capacity_policy.update!(exclusion_rules: {
                                  'excluded_labels' => [label1.title],
                                  'exclude_older_than_hours' => 24
                                })

        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        # Only recent conversation without label should be assigned
        expect(assigned_count).to eq(1)
        expect(old_conversation_with_label.reload.assignee).to be_nil
        expect(old_conversation_without_label.reload.assignee).to be_nil
        expect(recent_conversation_with_label.reload.assignee).to be_nil
        expect(recent_conversation_without_label.reload.assignee).to be_present
      end
    end

    context 'when exclusion rules are empty' do
      let!(:conversation1) { create(:conversation, inbox: inbox, assignee: nil) }
      let!(:conversation2) { create(:conversation, inbox: inbox, assignee: nil) }

      before do
        capacity_policy.update!(exclusion_rules: {})
      end

      it 'assigns all eligible conversations' do
        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        expect(assigned_count).to eq(2)
        expect(conversation1.reload.assignee).to be_present
        expect(conversation2.reload.assignee).to be_present
      end
    end

    context 'when no capacity policy exists' do
      let!(:conversation1) { create(:conversation, inbox: inbox, assignee: nil) }
      let!(:conversation2) { create(:conversation, inbox: inbox, assignee: nil) }

      before do
        InboxCapacityLimit.destroy_all
      end

      it 'assigns all eligible conversations without exclusions' do
        assigned_count = assignment_service.perform_bulk_assignment(limit: 10)

        expect(assigned_count).to eq(2)
        expect(conversation1.reload.assignee).to be_present
        expect(conversation2.reload.assignee).to be_present
      end
    end
  end
end
