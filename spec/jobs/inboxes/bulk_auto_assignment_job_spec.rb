require 'rails_helper'

RSpec.describe Inboxes::BulkAutoAssignmentJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { build(:conversation, account: account, inbox: inbox, assignee: nil) }

  before do
    inbox.add_members([agent.id])
    # Set agent as online for auto-assignment to work
    OnlineStatusTracker.set_status(account.id, agent.id, 'online')
    OnlineStatusTracker.update_presence(account.id, 'User', agent.id)
  end

  def create_conversation_without_auto_assignment
    # Temporarily disable auto-assignment to prevent immediate assignment
    inbox.update!(enable_auto_assignment: false)
    conversation.save!
    inbox.update!(enable_auto_assignment: true)
  end

  def create_conversation_without_auto_assignment_for(conv)
    # Temporarily disable auto-assignment to prevent immediate assignment
    conv.inbox.update!(enable_auto_assignment: false)
    conv.save!
    conv.inbox.update!(enable_auto_assignment: true)
  end

  describe '#perform' do
    it 'assigns unassigned conversations for inboxes with auto-assignment enabled' do
      create_conversation_without_auto_assignment
      expect(conversation.assignee).to be_nil

      described_class.perform_now

      conversation.reload
      expect(conversation.assignee).to eq(agent)
    end

    it 'skips inboxes with auto-assignment disabled' do
      create_conversation_without_auto_assignment
      inbox.update!(enable_auto_assignment: false)
      expect(conversation.assignee).to be_nil

      described_class.perform_now

      conversation.reload
      expect(conversation.assignee).to be_nil
    end

    it 'skips already assigned conversations' do
      conversation.update!(assignee: agent)
      expect(conversation.assignee).to eq(agent)

      described_class.perform_now

      conversation.reload
      expect(conversation.assignee).to eq(agent)
    end

    it 'skips closed conversations' do
      create_conversation_without_auto_assignment
      conversation.update!(status: :resolved)
      expect(conversation.assignee).to be_nil

      described_class.perform_now

      conversation.reload
      expect(conversation.assignee).to be_nil
    end

    it 'handles errors gracefully and continues processing' do
      create_conversation_without_auto_assignment
      allow_any_instance_of(AutoAssignment::AgentAssignmentService).to receive(:perform).and_raise(StandardError, 'Test error')
      logger = instance_double(ActiveSupport::Logger)
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:error)

      expect { described_class.perform_now }.not_to raise_error
      expect(logger).to have_received(:error).with(/Failed to auto-assign conversation/)
    end

    it 'limits processing to 100 conversations per inbox' do
      # Create 150 unassigned conversations in the same inbox
      150.times do
        conv = build(:conversation, account: account, inbox: inbox, assignee: nil)
        create_conversation_without_auto_assignment_for(conv)
      end

      # Mock the assignment service to track calls
      assignment_service = instance_double(AutoAssignment::AgentAssignmentService)
      allow(AutoAssignment::AgentAssignmentService).to receive(:new).and_return(assignment_service)
      allow(assignment_service).to receive(:perform).and_return(true)

      described_class.perform_now

      # Should only process 100 conversations per inbox
      expect(AutoAssignment::AgentAssignmentService).to have_received(:new).exactly(100).times
    end

    it 'processes multiple inboxes independently' do
      # Create a second inbox
      inbox2 = create(:inbox, account: account, enable_auto_assignment: true)
      inbox2.add_members([agent.id])

      # Create 50 conversations in first inbox
      50.times do
        conv = build(:conversation, account: account, inbox: inbox, assignee: nil)
        create_conversation_without_auto_assignment_for(conv)
      end

      # Create 75 conversations in second inbox
      75.times do
        conv = build(:conversation, account: account, inbox: inbox2, assignee: nil)
        create_conversation_without_auto_assignment_for(conv)
      end

      # Mock the assignment service to track calls
      assignment_service = instance_double(AutoAssignment::AgentAssignmentService)
      allow(AutoAssignment::AgentAssignmentService).to receive(:new).and_return(assignment_service)
      allow(assignment_service).to receive(:perform).and_return(true)

      described_class.perform_now

      # Should process 50 + 75 = 125 conversations total across both inboxes
      expect(AutoAssignment::AgentAssignmentService).to have_received(:new).exactly(125).times
    end
  end
end
