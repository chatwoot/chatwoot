require 'rails_helper'

RSpec.describe ConversationDrop do
  subject(:drop) { described_class.new(conversation) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, status: :open, assignee_id: nil)
  end

  describe '#queue_position' do
    context 'when one open unassigned conversation exists in the inbox' do
      it 'returns 1' do
        expect(drop.queue_position).to eq(1)
      end
    end

    context 'when multiple open unassigned conversations exist in the inbox' do
      before do
        create(:conversation, account: account, inbox: inbox, status: :open, assignee_id: nil)
      end

      it 'returns the total count including the current conversation' do
        expect(drop.queue_position).to eq(2)
      end
    end

    context 'when the conversation is assigned' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before { conversation.update!(assignee: agent) }

      it 'returns 0' do
        expect(drop.queue_position).to eq(0)
      end
    end

    context 'when the conversation is resolved' do
      before { conversation.update!(status: :resolved) }

      it 'returns 0' do
        expect(drop.queue_position).to eq(0)
      end
    end

    context 'when the conversation is pending' do
      before { conversation.update!(status: :pending) }

      it 'returns 0' do
        expect(drop.queue_position).to eq(0)
      end
    end
  end

  describe '#avg_wait_time_seconds and #avg_wait_time_minutes' do
    context 'when reporting data exists for the current day' do
      before do
        create(:reporting_event, account: account, inbox: inbox,
                                 name: 'first_response', value: 120.5,
                                 created_at: 1.hour.ago)
      end

      it 'returns avg first response as integer seconds' do
        expect(drop.avg_wait_time_seconds).to eq(120)
      end
    end

    context 'when there is no avg first response data' do
      it 'returns 0 seconds' do
        expect(drop.avg_wait_time_seconds).to eq(0)
      end

      it 'returns 0 minutes' do
        expect(drop.avg_wait_time_minutes).to eq(0)
      end
    end

    context 'when events belong to a different inbox' do
      let(:other_inbox) { create(:inbox, account: account) }

      before do
        create(:reporting_event, account: account, inbox: other_inbox,
                                 name: 'first_response', value: 300.0,
                                 created_at: 1.hour.ago)
      end

      it 'returns 0 (does not count other inbox events)' do
        expect(drop.avg_wait_time_seconds).to eq(0)
      end
    end

    context 'when average is under one minute' do
      before do
        create(:reporting_event, account: account, inbox: inbox,
                                 name: 'first_response', value: 45.0,
                                 created_at: 1.hour.ago)
      end

      it 'ceil minutes to 1' do
        expect(drop.avg_wait_time_minutes).to eq(1)
      end
    end

    context 'when average is an exact number of minutes' do
      before do
        create(:reporting_event, account: account, inbox: inbox,
                                 name: 'first_response', value: 300.0,
                                 created_at: 1.hour.ago)
      end

      it 'returns that many minutes' do
        expect(drop.avg_wait_time_minutes).to eq(5)
      end
    end

    context 'when average spans a fractional minute' do
      before do
        create(:reporting_event, account: account, inbox: inbox,
                                 name: 'first_response', value: 370.0,
                                 created_at: 1.hour.ago)
      end

      it 'ceil minutes' do
        expect(drop.avg_wait_time_minutes).to eq(7)
      end
    end

    it 'memoizes the result so both time accessors trigger a single DB query' do
      create(:reporting_event, account: account, inbox: inbox,
                               name: 'first_response', value: 60.0,
                               created_at: 1.hour.ago)

      expect(drop).to receive(:fetch_avg_first_response_seconds).once.and_call_original
      drop.avg_wait_time_seconds
      drop.avg_wait_time_minutes
    end

    context 'when account has a reporting_timezone set' do
      before do
        account.update!(reporting_timezone: 'America/Sao_Paulo')
        create(:reporting_event, account: account, inbox: inbox,
                                 name: 'first_response', value: 240.0,
                                 created_at: 1.hour.ago)
      end

      it 'scopes today using account reporting timezone' do
        expect(drop.avg_wait_time_seconds).to eq(240)
      end
    end
  end
end
