require 'rails_helper'

RSpec.describe AutoAssignment::AssignmentJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:agent) { create(:user, account: account, role: :agent, availability: :online) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  describe '#perform' do
    context 'when inbox exists' do
      context 'when auto assignment is enabled' do
        it 'calls the assignment service' do
          service = instance_double(AutoAssignment::AssignmentService)
          allow(AutoAssignment::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
          expect(service).to receive(:perform_bulk_assignment).with(limit: 100).and_return(5)

          described_class.new.perform(inbox_id: inbox.id)
        end

        it 'logs the assignment count' do
          service = instance_double(AutoAssignment::AssignmentService)
          allow(AutoAssignment::AssignmentService).to receive(:new).and_return(service)
          allow(service).to receive(:perform_bulk_assignment).and_return(3)

          expect(Rails.logger).to receive(:info).with("Assigned 3 conversations for inbox #{inbox.id}")

          described_class.new.perform(inbox_id: inbox.id)
        end

        it 'uses custom bulk limit from environment' do
          allow(ENV).to receive(:fetch).with('AUTO_ASSIGNMENT_BULK_LIMIT', 100).and_return('50')

          service = instance_double(AutoAssignment::AssignmentService)
          allow(AutoAssignment::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
          expect(service).to receive(:perform_bulk_assignment).with(limit: 50).and_return(2)

          described_class.new.perform(inbox_id: inbox.id)
        end
      end

      context 'when auto assignment is disabled' do
        before { inbox.update!(enable_auto_assignment: false) }

        it 'calls the service which handles the disabled state' do
          service = instance_double(AutoAssignment::AssignmentService)
          allow(AutoAssignment::AssignmentService).to receive(:new).with(inbox: inbox).and_return(service)
          expect(service).to receive(:perform_bulk_assignment).with(limit: 100).and_return(0)

          described_class.new.perform(inbox_id: inbox.id)
        end
      end
    end

    context 'when inbox does not exist' do
      it 'returns early without processing' do
        expect(AutoAssignment::AssignmentService).not_to receive(:new)

        described_class.new.perform(inbox_id: 999_999)
      end
    end

    context 'when an error occurs' do
      it 'logs the error and re-raises in test environment' do
        service = instance_double(AutoAssignment::AssignmentService)
        allow(AutoAssignment::AssignmentService).to receive(:new).and_return(service)
        allow(service).to receive(:perform_bulk_assignment).and_raise(StandardError, 'Something went wrong')

        expect(Rails.logger).to receive(:error).with("Bulk assignment failed for inbox #{inbox.id}: Something went wrong")

        expect do
          described_class.new.perform(inbox_id: inbox.id)
        end.to raise_error(StandardError, 'Something went wrong')
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in the default queue' do
      expect(described_class.queue_name).to eq('default')
    end
  end
end
