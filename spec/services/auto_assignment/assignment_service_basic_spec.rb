require 'rails_helper'

RSpec.describe AutoAssignment::AssignmentService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent, availability: :online) }
  let(:service) { described_class.new(inbox: inbox) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    allow(OnlineStatusTracker).to receive(:get_available_users)
      .and_return({ agent.id.to_s => 'online' })
  end

  def create_test_conversation(attrs = {})
    conversation = build(:conversation, attrs.reverse_merge(inbox: inbox, assignee: nil, status: :open))
    allow(conversation).to receive(:run_auto_assignment).and_return(nil)
    conversation.save!
    conversation
  end

  describe 'basic assignment' do
    context 'when auto assignment is enabled' do
      before { inbox.update!(enable_auto_assignment: true) }

      it 'assigns an available agent to conversation' do
        conversation = create_test_conversation

        assigned_count = service.perform_bulk_assignment(limit: 1)

        expect(assigned_count).to eq(1)
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'returns 0 when no agents are online' do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({})
        conversation = create_test_conversation

        assigned_count = service.perform_bulk_assignment(limit: 1)

        expect(assigned_count).to eq(0)
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'when auto assignment is disabled' do
      before { inbox.update!(enable_auto_assignment: false) }

      it 'does not assign any agent' do
        conversation = create_test_conversation

        assigned_count = service.perform_bulk_assignment(limit: 1)

        expect(assigned_count).to eq(0)
        expect(conversation.reload.assignee).to be_nil
      end
    end
  end

  describe 'assignment conditions' do
    before { inbox.update!(enable_auto_assignment: true) }

    it 'only assigns to open conversations' do
      resolved_conversation = create_test_conversation(status: 'resolved')

      assigned_count = service.perform_bulk_assignment(limit: 1)

      expect(assigned_count).to eq(0)
      expect(resolved_conversation.reload.assignee).to be_nil
    end

    it 'does not reassign already assigned conversations' do
      other_agent = create(:user, account: account, role: :agent)
      assigned_conversation = create_test_conversation(assignee: other_agent)

      assigned_count = service.perform_bulk_assignment(limit: 1)

      expect(assigned_count).to eq(0)
      expect(assigned_conversation.reload.assignee).to eq(other_agent)
    end
  end
end
