require 'rails_helper'

RSpec.describe V2::Reports::BotMetricsBuilder do
  subject(:bot_metrics_builder) { described_class.new(inbox.account, params) }

  let(:inbox) { create(:inbox) }
  let(:since) { 1.week.ago.to_i.to_s }
  let(:until_time) { Time.now.to_i.to_s }
  let(:params) { { since: since, until: until_time } }

  before do
    create(:agent_bot_inbox, inbox: inbox)
  end

  describe '#metrics' do
    context 'with valid params' do
      let!(:resolved_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }
      let!(:handoff_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }

      before do
        create(:message, account: inbox.account, conversation: resolved_conversation, created_at: 2.days.ago, message_type: 'outgoing')
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_resolved',
                                 conversation_id: resolved_conversation.id, created_at: 2.days.ago)
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_handoff',
                                 conversation_id: handoff_conversation.id, created_at: 2.days.ago)
      end

      it 'returns correct metrics' do
        metrics = bot_metrics_builder.metrics

        expect(metrics[:conversation_count]).to eq(2)
        expect(metrics[:message_count]).to eq(1)
        expect(metrics[:resolution_rate]).to eq(50)
        expect(metrics[:handoff_rate]).to eq(50)
      end
    end

    context 'when a conversation has both bot_resolved and bot_handoff events in the same range' do
      let!(:double_counted_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }
      let!(:handoff_only_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }

      before do
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_resolved',
                                 conversation_id: double_counted_conversation.id, created_at: 2.days.ago)
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_handoff',
                                 conversation_id: double_counted_conversation.id, created_at: 2.days.ago)
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_handoff',
                                 conversation_id: handoff_only_conversation.id, created_at: 2.days.ago)
      end

      it 'excludes the conversation from resolution count — handoff wins' do
        metrics = bot_metrics_builder.metrics

        expect(metrics[:conversation_count]).to eq(2)
        expect(metrics[:resolution_rate]).to eq(0)
        expect(metrics[:handoff_rate]).to eq(100)
      end
    end

    context 'when bot_resolved and bot_handoff are in different date ranges' do
      let!(:multi_cycle_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }

      before do
        # Bot resolved in current range
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_resolved',
                                 conversation_id: multi_cycle_conversation.id, created_at: 2.days.ago)
        # Handoff happened before the range (in a previous cycle)
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_handoff',
                                 conversation_id: multi_cycle_conversation.id, created_at: 2.weeks.ago)
      end

      it 'counts the resolution since the handoff is outside the range' do
        metrics = bot_metrics_builder.metrics

        expect(metrics[:conversation_count]).to eq(1)
        expect(metrics[:resolution_rate]).to eq(100)
        expect(metrics[:handoff_rate]).to eq(0)
      end
    end

    context 'when a bot_handoff event has no conversation' do
      let!(:resolved_conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }

      before do
        create(:reporting_event, account_id: inbox.account.id, name: 'conversation_bot_resolved',
                                 conversation_id: resolved_conversation.id, created_at: 2.days.ago)
        create(:reporting_event, account: inbox.account, inbox: inbox, conversation: nil, conversation_id: nil,
                                 name: 'conversation_bot_handoff', created_at: 2.days.ago)
      end

      it 'does not exclude all bot resolutions' do
        metrics = bot_metrics_builder.metrics

        expect(metrics[:conversation_count]).to eq(1)
        expect(metrics[:resolution_rate]).to eq(100)
        expect(metrics[:handoff_rate]).to eq(0)
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
