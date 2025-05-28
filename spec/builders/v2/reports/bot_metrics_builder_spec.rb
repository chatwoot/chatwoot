require 'rails_helper'

RSpec.describe V2::Reports::BotMetricsBuilder do
  subject(:bot_metrics_builder) { described_class.new(inbox.account, params) }

  let(:inbox) { create(:inbox) }
  let!(:resolved_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }
  let!(:unresolved_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }
  let(:since) { 1.week.ago.to_i.to_s }
  let(:until_time) { Time.now.to_i.to_s }
  let(:params) { { since: since, until: until_time } }

  before do
    create(:agent_bot_inbox, inbox: inbox)
    create(:message, account: inbox.account, conversation: resolved_conversation, created_at: 2.days.ago, message_type: 'outgoing')
    create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_resolved', conversation_id: resolved_conversation.id,
                             created_at: 2.days.ago)
    create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_handoff',
                             conversation_id: resolved_conversation.id, created_at: 2.days.ago)
    create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_handoff',
                             conversation_id: unresolved_conversation.id, created_at: 2.days.ago)
  end

  describe '#metrics' do
    context 'with valid params' do
      it 'returns correct metrics' do
        metrics = bot_metrics_builder.metrics

        expect(metrics[:conversation_count]).to eq(2)
        expect(metrics[:message_count]).to eq(1)
        expect(metrics[:resolution_rate]).to eq(50)
        expect(metrics[:handoff_rate]).to eq(100)
      end
    end

    context 'with missing params' do
      let(:params) { {} }

      it 'handles missing since and until params gracefully' do
        expect { bot_metrics_builder.metrics }.not_to raise_error
      end
    end
  end
end
