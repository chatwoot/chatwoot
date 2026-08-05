require 'rails_helper'

RSpec.describe BulkActionsJob do
  subject(:job) { described_class.perform_later(account: account, params: params, user: agent) }

  let(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation_1) { create(:conversation, account_id: account.id, status: :open) }
  let!(:conversation_2) { create(:conversation, account_id: account.id, status: :open) }
  let!(:conversation_3) { create(:conversation, account_id: account.id, status: :open) }
  let(:conversation_ids) { [conversation_1.display_id, conversation_2.display_id, conversation_3.display_id] }
  let(:params) { { type: 'Conversation', fields: { status: 'snoozed' }, ids: conversation_ids } }

  before do
    [conversation_1, conversation_2, conversation_3].each do |conversation|
      create(:inbox_member, inbox: conversation.inbox, user: agent)
    end
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account: account, params: params, user: agent)
      .on_queue('medium')
  end

  context 'when job is triggered' do
    let(:bulk_action_job) { double }

    before do
      allow(bulk_action_job).to receive(:perform)
    end

    it 'bulk updates the status' do
      params = {
        type: 'Conversation',
        fields: { status: 'snoozed', assignee_id: agent.id },
        ids: conversation_ids
      }

      expect(conversation_1.status).to eq('open')

      described_class.perform_now(account: account, params: params, user: agent)

      expect(conversation_1.reload.status).to eq('snoozed')
      expect(conversation_2.reload.status).to eq('snoozed')
      expect(conversation_3.reload.status).to eq('snoozed')
    end

    it 'bulk updates the assignee_id' do
      params = {
        type: 'Conversation',
        fields: { status: 'snoozed', assignee_id: agent.id },
        ids: conversation_ids
      }

      expect(conversation_1.assignee_id).to be_nil

      described_class.perform_now(account: account, params: params, user: agent)

      expect(conversation_1.reload.assignee_id).to eq(agent.id)
      expect(conversation_2.reload.assignee_id).to eq(agent.id)
      expect(conversation_3.reload.assignee_id).to eq(agent.id)
    end

    it 'bulk updates the snoozed_until' do
      params = {
        type: 'Conversation',
        fields: { status: 'snoozed', snoozed_until: Time.zone.now },
        ids: conversation_ids
      }

      expect(conversation_1.snoozed_until).to be_nil

      described_class.perform_now(account: account, params: params, user: agent)

      expect(conversation_1.reload.snoozed_until).to be_present
      expect(conversation_2.reload.snoozed_until).to be_present
      expect(conversation_3.reload.snoozed_until).to be_present
    end

    it 'skips conversations whose inbox the agent does not belong to' do
      forbidden_conversation = create(:conversation, account_id: account.id, status: :open)
      params = {
        type: 'Conversation',
        fields: { status: 'resolved' },
        ids: [conversation_1.display_id, forbidden_conversation.display_id]
      }

      described_class.perform_now(account: account, params: params, user: agent)

      expect(conversation_1.reload.status).to eq('resolved')
      expect(forbidden_conversation.reload.status).to eq('open')
    end
  end
end
