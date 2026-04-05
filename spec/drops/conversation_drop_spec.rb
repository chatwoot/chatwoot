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

      before do
        conversation.update!(assignee: agent)
      end

      it 'returns 0' do
        expect(drop.queue_position).to eq(0)
      end
    end
  end

  describe '#avg_wait_time_seconds and #avg_wait_time_minutes' do
    let(:builder_instance) { instance_double(V2::Reports::AccountSummaryBuilder) }

    before do
      allow(V2::Reports::AccountSummaryBuilder).to receive(:new).and_return(builder_instance)
    end

    context 'when reporting data exists for the current day' do
      before do
        allow(builder_instance).to receive(:build).and_return(
          [{ avg_first_response_time: 120.5 }]
        )
      end

      it 'returns avg first response as integer seconds' do
        expect(drop.avg_wait_time_seconds).to eq(120)
      end
    end

    context 'when there is no avg first response data' do
      before do
        allow(builder_instance).to receive(:build).and_return(
          [{ avg_first_response_time: nil }]
        )
      end

      it 'returns 0 seconds' do
        expect(drop.avg_wait_time_seconds).to eq(0)
      end

      it 'returns 0 minutes' do
        expect(drop.avg_wait_time_minutes).to eq(0)
      end
    end

    context 'when average is under one minute' do
      before do
        allow(builder_instance).to receive(:build).and_return(
          [{ avg_first_response_time: 45.0 }]
        )
      end

      it 'ceil minutes to 1' do
        expect(drop.avg_wait_time_minutes).to eq(1)
      end
    end

    context 'when average is an exact number of minutes' do
      before do
        allow(builder_instance).to receive(:build).and_return(
          [{ avg_first_response_time: 300.0 }]
        )
      end

      it 'returns that many minutes' do
        expect(drop.avg_wait_time_minutes).to eq(5)
      end
    end

    context 'when average spans a fractional minute' do
      before do
        allow(builder_instance).to receive(:build).and_return(
          [{ avg_first_response_time: 370.0 }]
        )
      end

      it 'ceil minutes' do
        expect(drop.avg_wait_time_minutes).to eq(7)
      end
    end

    it 'memoizes the summary so both time accessors trigger a single build' do
      allow(builder_instance).to receive(:build).and_return(
        [{ avg_first_response_time: 60.0 }]
      )

      drop.avg_wait_time_seconds
      drop.avg_wait_time_minutes

      expect(builder_instance).to have_received(:build).once
    end
  end
end
