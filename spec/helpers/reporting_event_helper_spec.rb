require 'rails_helper'

RSpec.describe ReportingEventHelper, type: :helper do
  describe '#last_non_human_activity' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

    context 'when conversation has no events' do
      it 'returns conversation created_at' do
        expect(helper.last_non_human_activity(conversation)).to eq(conversation.created_at)
      end
    end

    context 'when conversation has bot handoff event' do
      let!(:handoff_event) do
        create(:reporting_event,
               name: 'conversation_bot_handoff',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_end_time: 2.hours.ago)
      end

      it 'returns handoff event end time' do
        expect(helper.last_non_human_activity(conversation).to_i).to eq(handoff_event.event_end_time.to_i)
      end
    end

    context 'when conversation has bot resolved event' do
      let!(:bot_resolved_event) do
        create(:reporting_event,
               name: 'conversation_bot_resolved',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_end_time: 3.hours.ago)
      end

      it 'returns bot resolved event end time' do
        expect(helper.last_non_human_activity(conversation).to_i).to eq(bot_resolved_event.event_end_time.to_i)
      end
    end

    context 'when conversation is reopened after bot resolution' do
      let(:creation_time) { 5.days.ago }
      let(:bot_resolution_time) { 5.days.ago + 5.minutes }
      let(:reopening_time) { 1.hour.ago }

      let!(:conversation) do
        create(:conversation,
               account: account,
               inbox: inbox,
               assignee: user,
               created_at: creation_time)
      end

      before do
        # First opened event
        create(:reporting_event,
               name: 'conversation_opened',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               value: 0,
               event_start_time: creation_time,
               event_end_time: creation_time)

        # Bot resolved event
        create(:reporting_event,
               name: 'conversation_bot_resolved',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_start_time: creation_time,
               event_end_time: bot_resolution_time)

        # Resolved event
        create(:reporting_event,
               name: 'conversation_resolved',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_start_time: creation_time,
               event_end_time: bot_resolution_time)

        # Reopened event
        create(:reporting_event,
               name: 'conversation_opened',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               value: (reopening_time - bot_resolution_time).to_i,
               event_start_time: bot_resolution_time,
               event_end_time: reopening_time)
      end

      it 'returns the reopening event time, not the creation time' do
        # This is the key test: last_non_human_activity should return the reopening time
        # so that first response time is calculated from when the conversation was reopened,
        # not from when it was originally created
        expect(helper.last_non_human_activity(conversation).to_i).to eq(reopening_time.to_i)

        # Verify it's not returning the creation time or bot resolution time
        expect(helper.last_non_human_activity(conversation).to_i).not_to eq(creation_time.to_i)
        expect(helper.last_non_human_activity(conversation).to_i).not_to eq(bot_resolution_time.to_i)
      end
    end

    context 'when conversation has multiple types of events' do
      let(:opened_event_time) { 1.hour.ago }

      before do
        create(:reporting_event,
               name: 'conversation_bot_resolved',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_end_time: 4.hours.ago)

        create(:reporting_event,
               name: 'conversation_bot_handoff',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_end_time: 3.hours.ago)

        create(:reporting_event,
               name: 'conversation_opened',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               event_end_time: opened_event_time)
      end

      it 'returns the most recent handoff or opened event' do
        # opened_event is more recent than handoff_event
        expect(helper.last_non_human_activity(conversation).to_i).to eq(opened_event_time.to_i)
      end
    end

    context 'when conversation has multiple reopenings' do
      let(:third_opened_time) { 30.minutes.ago }

      before do
        create(:reporting_event,
               name: 'conversation_opened',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               value: 0,
               event_end_time: 5.days.ago)

        create(:reporting_event,
               name: 'conversation_opened',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               value: 3600,
               event_end_time: 2.days.ago)

        create(:reporting_event,
               name: 'conversation_opened',
               conversation_id: conversation.id,
               account_id: account.id,
               inbox_id: inbox.id,
               value: 7200,
               event_end_time: third_opened_time)
      end

      it 'returns the most recent opened event' do
        expect(helper.last_non_human_activity(conversation).to_i).to eq(third_opened_time.to_i)
      end
    end
  end
end
