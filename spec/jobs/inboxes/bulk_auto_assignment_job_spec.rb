require 'rails_helper'

RSpec.describe Inboxes::BulkAutoAssignmentJob do
  let(:account) { create(:account, custom_attributes: { 'plan_name' => 'Startups' }) }
  let(:agent) { create(:user, account: account, role: :agent, auto_offline: false) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: nil, status: :open) }
  let(:assignment_service) { double }

  describe '#perform' do
    before do
      allow(assignment_service).to receive(:perform)
    end

    context 'when inbox has inbox members' do
      before do
        create(:inbox_member, user: agent, inbox: inbox)
        account.enable_features!('assignment_v2')
        inbox.update!(enable_auto_assignment: true)
      end

      it 'assigns unassigned conversations in enabled inboxes' do
        allow(AutoAssignment::AgentAssignmentService).to receive(:new).with(
          conversation: conversation,
          allowed_agent_ids: [agent.id]
        ).and_return(assignment_service)

        described_class.perform_now
        expect(AutoAssignment::AgentAssignmentService).to have_received(:new).with(
          conversation: conversation,
          allowed_agent_ids: [agent.id]
        )
      end

      it 'skips inboxes with auto assignment disabled' do
        inbox.update!(enable_auto_assignment: false)
        allow(AutoAssignment::AgentAssignmentService).to receive(:new)

        described_class.perform_now

        expect(AutoAssignment::AgentAssignmentService).not_to have_received(:new).with(
          conversation: conversation,
          allowed_agent_ids: [agent.id]
        )
      end

      context 'when account is on default plan in chatwoot cloud' do
        before do
          account.update!(custom_attributes: {})
          InstallationConfig.create!(name: 'CHATWOOT_CLOUD_PLANS', value: [{ 'name' => 'default' }])
          allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        end

        it 'skips auto assignment' do
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with("Skipping auto assignment for account #{account.id}")

          allow(AutoAssignment::AgentAssignmentService).to receive(:new)
          expect(AutoAssignment::AgentAssignmentService).not_to receive(:new)

          described_class.perform_now
        end
      end
    end

    context 'when inbox has no members' do
      before do
        account.enable_features!('assignment_v2')
        inbox.update!(enable_auto_assignment: true)
      end

      it 'does not assign conversations' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("No agents available to assign conversation to inbox #{inbox.id}")

        described_class.perform_now
      end
    end

    context 'when assignment_v2 feature is disabled' do
      before do
        account.disable_features!('assignment_v2')
      end

      it 'skips auto assignment' do
        allow(AutoAssignment::AgentAssignmentService).to receive(:new)
        expect(AutoAssignment::AgentAssignmentService).not_to receive(:new)

        described_class.perform_now
      end
    end
  end
end
