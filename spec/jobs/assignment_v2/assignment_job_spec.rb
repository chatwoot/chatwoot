# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::AssignmentJob, type: :job do
  before do
    # Mock GlobalConfig to avoid InstallationConfig issues
    allow(GlobalConfig).to receive(:get).and_return({})
  end

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, assignee: nil) }
  let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }
  let!(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }

  describe '#perform' do
    context 'with conversation_id' do
      it 'assigns a single conversation' do
        service = instance_double(AssignmentV2::AssignmentService)
        expect(AssignmentV2::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
        expect(service).to receive(:perform_for_conversation).with(conversation)

        described_class.new.perform(conversation_id: conversation.id)
      end

      it 'handles non-existent conversation gracefully' do
        expect(AssignmentV2::AssignmentService).not_to receive(:new)

        # Should not raise error
        expect do
          described_class.new.perform(conversation_id: 999_999)
        end.not_to raise_error
      end
    end

    context 'with inbox_id' do
      let!(:agent) { create(:user, account: account, role: :agent, availability: :online) }

      before do
        create_list(:conversation, 3, inbox: inbox, assignee: nil)
        create(:inbox_member, inbox: inbox, user: agent)
      end

      it 'assigns multiple conversations for inbox' do
        # Mock the feature flag for assignment_v2
        allow(inbox.account).to receive(:feature_enabled?).with('assignment_v2').and_return(true)
        allow(Inbox).to receive(:find_by).with(id: inbox.id).and_return(inbox)

        service = instance_double(AssignmentV2::AssignmentService)
        expect(AssignmentV2::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
        expect(service).to receive(:perform_bulk_assignment).and_return(3)

        described_class.new.perform(inbox_id: inbox.id)
      end

      it 'logs the number of assigned conversations' do
        # Mock the feature flag for assignment_v2
        allow(inbox.account).to receive(:feature_enabled?).with('assignment_v2').and_return(true)
        allow(Inbox).to receive(:find_by).with(id: inbox.id).and_return(inbox)

        service = instance_double(AssignmentV2::AssignmentService)
        allow(AssignmentV2::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
        allow(service).to receive(:perform_bulk_assignment).and_return(2)

        expect(Rails.logger).to receive(:info).with("AssignmentV2::AssignmentJob: Assigned 2 conversations for inbox #{inbox.id}")

        described_class.new.perform(inbox_id: inbox.id)
      end

      it 'skips assignment when inbox has no policy' do
        inbox_assignment_policy.destroy!

        expect(AssignmentV2::AssignmentService).not_to receive(:new)

        described_class.new.perform(inbox_id: inbox.id)
      end

      it 'skips assignment when policy is disabled' do
        assignment_policy.update!(enabled: false)

        expect(AssignmentV2::AssignmentService).not_to receive(:new)

        described_class.new.perform(inbox_id: inbox.id)
      end

      it 'handles non-existent inbox gracefully' do
        expect(AssignmentV2::AssignmentService).not_to receive(:new)

        # Should not raise error
        expect do
          described_class.new.perform(inbox_id: 999_999)
        end.not_to raise_error
      end
    end

    context 'without parameters' do
      it 'logs error when no parameters provided' do
        expect(Rails.logger).to receive(:error).with('AssignmentV2::AssignmentJob: No inbox_id or conversation_id provided')

        described_class.new.perform
      end

      it 'does not attempt assignment' do
        expect(AssignmentV2::AssignmentService).not_to receive(:new)

        described_class.new.perform
      end
    end

    context 'with both parameters' do
      it 'prioritizes conversation_id over inbox_id' do
        service = instance_double(AssignmentV2::AssignmentService)
        expect(AssignmentV2::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
        expect(service).to receive(:perform_for_conversation).with(conversation)
        expect(service).not_to receive(:perform_bulk_assignment)

        described_class.new.perform(conversation_id: conversation.id, inbox_id: inbox.id)
      end
    end
  end

  describe 'job configuration' do
    it 'uses the low queue' do
      expect(described_class.new.queue_name).to eq('low')
    end
  end

  describe 'error handling' do
    context 'when assignment service raises error' do
      it 'propagates the error for retry' do
        service = instance_double(AssignmentV2::AssignmentService)
        allow(AssignmentV2::AssignmentService).to receive(:new).and_return(service)
        allow(service).to receive(:perform_for_conversation).and_raise(StandardError, 'Assignment failed')

        expect do
          described_class.new.perform(conversation_id: conversation.id)
        end.to raise_error(StandardError, 'Assignment failed')
      end
    end

    context 'when database connection fails' do
      it 'raises error for retry' do
        allow(Conversation).to receive(:find_by).and_raise(ActiveRecord::ConnectionNotEstablished)

        expect do
          described_class.new.perform(conversation_id: conversation.id)
        end.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end
    end
  end

  describe 'concurrency and idempotency' do
    it 'handles concurrent job execution safely' do
      # Create multiple jobs for same inbox
      jobs = []
      3.times { jobs << described_class.new }

      # All should execute without issues
      expect do
        jobs.each { |job| job.perform(inbox_id: inbox.id) }
      end.not_to raise_error
    end

    it 'is idempotent for conversation assignment' do
      service = instance_double(AssignmentV2::AssignmentService)
      allow(AssignmentV2::AssignmentService).to receive(:new).and_return(service)

      # First call assigns
      expect(service).to receive(:perform_for_conversation).and_return(true)
      described_class.new.perform(conversation_id: conversation.id)

      # Second call should handle already assigned conversation
      expect(service).to receive(:perform_for_conversation).and_return(false)
      expect { described_class.new.perform(conversation_id: conversation.id) }.not_to raise_error
    end
  end

  describe 'performance considerations' do
    it 'processes large inbox assignments in batches' do
      # Create many unassigned conversations
      create_list(:conversation, 100, inbox: inbox, assignee: nil)
      # Mock the feature flag for assignment_v2
      allow(inbox.account).to receive(:feature_enabled?).with('assignment_v2').and_return(true)
      allow(Inbox).to receive(:find_by).with(id: inbox.id).and_return(inbox)

      service = instance_double(AssignmentV2::AssignmentService)
      allow(AssignmentV2::AssignmentService).to receive(:new).and_return(service)

      # Service should be called with default limit
      expect(service).to receive(:perform_bulk_assignment).with(no_args).and_return(50)

      described_class.new.perform(inbox_id: inbox.id)
    end
  end
end
