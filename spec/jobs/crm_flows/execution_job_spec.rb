# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrmFlows::ExecutionJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, :with_email, account: account) }
  let(:conversation) { create(:conversation, account: account, contact: contact) }
  let(:idempotency_key) { SecureRandom.uuid }

  let(:metadata) do
    { 'ticket_subject' => 'Support Request', 'ticket_description' => 'Need help with product' }
  end

  describe '#perform with ticket_created trigger' do
    let(:flow) do
      create(:crm_flow,
             account: account,
             trigger_type: 'ticket_created',
             actions: [{ 'order' => 1, 'action' => 'create_ticket', 'type' => 'desk', 'params' => {} }])
    end

    let(:action_executor) { instance_double(CrmFlows::ActionExecutor) }

    before do
      allow(CrmFlows::ActionExecutor).to receive(:new).and_return(action_executor)
      allow(CrmFlows::IdempotencyService).to receive(:store_completed)
    end

    context 'when create_ticket action succeeds' do
      before do
        allow(action_executor).to receive(:execute).and_return([
          { action: 'create_ticket', crm: 'zoho', status: 'success', external_id: 'zoho_ticket_789', type: 'crm' }
        ])
      end

      it 'creates a local Ticket record from metadata' do
        expect do
          described_class.new.perform(
            flow_id: flow.id,
            conversation_id: conversation.id,
            contact_id: contact.id,
            metadata: metadata,
            idempotency_key: idempotency_key
          )
        end.to change(Ticket, :count).by(1)

        ticket = Ticket.last
        expect(ticket.subject).to eq('Support Request')
        expect(ticket.description).to eq('Need help with product')
        expect(ticket.account).to eq(account)
        expect(ticket.contact).to eq(contact)
        expect(ticket.conversation).to eq(conversation)
      end

      it 'stores the external ticket ID from CRM results' do
        described_class.new.perform(
          flow_id: flow.id,
          conversation_id: conversation.id,
          contact_id: contact.id,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        ticket = Ticket.last
        expect(ticket.external_ids['zoho']).to eq('zoho_ticket_789')
      end

      it 'creates a CrmFlowExecution with success status' do
        described_class.new.perform(
          flow_id: flow.id,
          conversation_id: conversation.id,
          contact_id: contact.id,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        execution = CrmFlowExecution.last
        expect(execution.status).to eq('success')
        expect(execution.trigger_type).to eq('ticket_created')
        expect(execution.crm_flow).to eq(flow)
      end
    end

    context 'when create_ticket action fails' do
      before do
        allow(action_executor).to receive(:execute).and_return([
          { action: 'create_ticket', crm: 'zoho', status: 'failed', error: 'API error', type: 'crm' }
        ])
      end

      it 'still creates a local Ticket record' do
        expect do
          described_class.new.perform(
            flow_id: flow.id,
            conversation_id: conversation.id,
            contact_id: contact.id,
            metadata: metadata,
            idempotency_key: idempotency_key
          )
        end.to change(Ticket, :count).by(1)
      end

      it 'does not store external IDs on the ticket' do
        described_class.new.perform(
          flow_id: flow.id,
          conversation_id: conversation.id,
          contact_id: contact.id,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        ticket = Ticket.last
        expect(ticket.external_ids).to eq({})
      end

      it 'records execution as failed' do
        described_class.new.perform(
          flow_id: flow.id,
          conversation_id: conversation.id,
          contact_id: contact.id,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        expect(CrmFlowExecution.last.status).to eq('failed')
      end
    end

    context 'when metadata uses subject/description keys instead of ticket_ prefixed' do
      let(:metadata) { { 'subject' => 'Fallback Subject', 'description' => 'Fallback Description' } }

      before do
        allow(action_executor).to receive(:execute).and_return([
          { action: 'create_ticket', crm: 'zoho', status: 'success', external_id: 'z1', type: 'crm' }
        ])
      end

      it 'falls back to subject/description keys' do
        described_class.new.perform(
          flow_id: flow.id,
          conversation_id: conversation.id,
          contact_id: contact.id,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        ticket = Ticket.last
        expect(ticket.subject).to eq('Fallback Subject')
        expect(ticket.description).to eq('Fallback Description')
      end
    end
  end

  describe '#perform with non-ticket trigger' do
    let(:flow) do
      create(:crm_flow,
             account: account,
             trigger_type: 'quote_request',
             actions: [{ 'order' => 1, 'action' => 'create_lead', 'type' => 'crm', 'params' => {} }])
    end

    let(:action_executor) { instance_double(CrmFlows::ActionExecutor) }

    before do
      allow(CrmFlows::ActionExecutor).to receive(:new).and_return(action_executor)
      allow(action_executor).to receive(:execute).and_return([
        { action: 'create_lead', crm: 'zoho', status: 'success', external_id: 'lead_123', type: 'crm' }
      ])
      allow(CrmFlows::IdempotencyService).to receive(:store_completed)
    end

    it 'does not create a Ticket record' do
      expect do
        described_class.new.perform(
          flow_id: flow.id,
          conversation_id: conversation.id,
          contact_id: contact.id,
          metadata: { 'amount' => 1000 },
          idempotency_key: idempotency_key
        )
      end.not_to change(Ticket, :count)
    end
  end
end
