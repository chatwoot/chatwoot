require 'rails_helper'

RSpec.describe BulkActionsJob do
  params = {
    type: 'Conversation',
    fields: { status: 'snoozed' },
    ids: Conversation.first(3).pluck(:display_id)
  }

  subject(:job) { described_class.perform_later(account: account, params: params, user: agent) }

  let(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation_1) { create(:conversation, account_id: account.id, status: :open) }
  let!(:conversation_2) { create(:conversation, account_id: account.id, status: :open) }
  let!(:conversation_3) { create(:conversation, account_id: account.id, status: :open) }

  before do
    Conversation.all.find_each do |conversation|
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
        ids: Conversation.first(3).pluck(:display_id)
      }

      expect(Conversation.first.status).to eq('open')

      described_class.perform_now(account: account, params: params, user: agent)

      expect(conversation_1.reload.status).to eq('snoozed')
      expect(conversation_2.reload.status).to eq('snoozed')
      expect(conversation_3.reload.status).to eq('snoozed')
    end

    it 'bulk updates the assignee_id' do
      params = {
        type: 'Conversation',
        fields: { status: 'snoozed', assignee_id: agent.id },
        ids: Conversation.first(3).pluck(:display_id)
      }

      expect(Conversation.first.assignee_id).to be_nil

      described_class.perform_now(account: account, params: params, user: agent)

      expect(Conversation.first.assignee_id).to eq(agent.id)
      expect(Conversation.second.assignee_id).to eq(agent.id)
      expect(Conversation.third.assignee_id).to eq(agent.id)
    end

    it 'bulk updates the snoozed_until' do
      params = {
        type: 'Conversation',
        fields: { status: 'snoozed', snoozed_until: Time.zone.now },
        ids: Conversation.first(3).pluck(:display_id)
      }

      expect(Conversation.first.snoozed_until).to be_nil

      described_class.perform_now(account: account, params: params, user: agent)

      expect(Conversation.first.snoozed_until).to be_present
      expect(Conversation.second.snoozed_until).to be_present
      expect(Conversation.third.snoozed_until).to be_present
    end
  end
end
