require 'rails_helper'

describe ReportingEvents::RollupService do
  describe '.perform' do
    let(:account) { create(:account, reporting_timezone: 'America/New_York') }
    let(:user) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
    let(:team) { create(:team, account: account) }

    context 'when reporting_timezone is not set' do
      before { account.update!(reporting_timezone: nil) }

      it 'skips rollup creation' do
        reporting_event = create(:reporting_event,
                                 account: account,
                                 name: 'conversation_resolved',
                                 conversation: conversation)

        expect do
          described_class.perform(reporting_event)
        end.not_to change(ReportingEventsRollup, :count)
      end
    end

    context 'when reporting_timezone is set' do
      describe 'conversation_resolved event' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'conversation_resolved',
                 value: 1000,
                 value_in_business_hours: 500,
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'creates rollup rows for all dimensions' do
          described_class.perform(reporting_event)

          # Account dimension
          account_row = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            dimension_id: account.id,
            metric: 'resolutions_count'
          )
          expect(account_row).to be_present

          # Agent dimension
          agent_row = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'agent',
            dimension_id: user.id,
            metric: 'resolutions_count'
          )
          expect(agent_row).to be_present

          # Inbox dimension
          inbox_row = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'inbox',
            dimension_id: inbox.id,
            metric: 'resolutions_count'
          )
          expect(inbox_row).to be_present
        end

        it 'creates correct metrics for conversation_resolved' do
          described_class.perform(reporting_event)

          resolutions_count = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'resolutions_count'
          )
          expect(resolutions_count.count).to eq(1)
          expect(resolutions_count.sum_value).to eq(0)
          expect(resolutions_count.sum_value_business_hours).to eq(0)

          resolution_time = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'resolution_time'
          )
          expect(resolution_time.count).to eq(1)
          expect(resolution_time.sum_value).to eq(1000)
          expect(resolution_time.sum_value_business_hours).to eq(500)
        end

        it 'respects account timezone for date bucketing' do
          # Event created at 2026-02-11 22:00 UTC
          # In EST (UTC-5) that's 2026-02-11 17:00 (same day)
          reporting_event.update!(created_at: '2026-02-11 22:00:00 UTC')

          described_class.perform(reporting_event)

          rollup = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account'
          )
          expect(rollup.date).to eq('2026-02-11'.to_date)
        end

        it 'handles timezone boundary crossing' do
          # Event created at 2026-02-12 04:00 UTC
          # In EST (UTC-5) that's 2026-02-11 23:00 (previous day)
          reporting_event.update!(created_at: '2026-02-12 04:00:00 UTC')

          described_class.perform(reporting_event)

          rollup = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account'
          )
          expect(rollup.date).to eq('2026-02-11'.to_date)
        end
      end

      describe 'first_response event' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'first_response',
                 value: 500,
                 value_in_business_hours: 300,
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'creates first_response metric' do
          described_class.perform(reporting_event)

          first_response = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'first_response'
          )
          expect(first_response).to be_present
          expect(first_response.count).to eq(1)
          expect(first_response.sum_value).to eq(500)
          expect(first_response.sum_value_business_hours).to eq(300)
        end
      end

      describe 'reply_time event' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'reply_time',
                 value: 200,
                 value_in_business_hours: 100,
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'creates reply_time metric' do
          described_class.perform(reporting_event)

          reply_time = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'reply_time'
          )
          expect(reply_time).to be_present
          expect(reply_time.count).to eq(1)
          expect(reply_time.sum_value).to eq(200)
          expect(reply_time.sum_value_business_hours).to eq(100)
        end
      end

      describe 'conversation_bot_resolved event' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'conversation_bot_resolved',
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'creates bot_resolutions_count metric' do
          described_class.perform(reporting_event)

          bot_resolutions = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'bot_resolutions_count'
          )
          expect(bot_resolutions).to be_present
          expect(bot_resolutions.count).to eq(1)
          expect(bot_resolutions.sum_value).to eq(0)
        end
      end

      describe 'conversation_bot_handoff event' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'conversation_bot_handoff',
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'creates bot_handoffs_count metric' do
          described_class.perform(reporting_event)

          bot_handoffs = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'bot_handoffs_count'
          )
          expect(bot_handoffs).to be_present
          expect(bot_handoffs.count).to eq(1)
          expect(bot_handoffs.sum_value).to eq(0)
        end
      end

      describe 'dimension handling' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'conversation_resolved',
                 value: 1000,
                 value_in_business_hours: 500,
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'skips dimensions with nil IDs' do
          # Create event without user (user_id will be nil)
          reporting_event.update!(user_id: nil)

          described_class.perform(reporting_event)

          # Agent dimension should not be created
          agent_rows = ReportingEventsRollup.where(
            account_id: account.id,
            dimension_type: 'agent'
          )
          expect(agent_rows).to be_empty
        end

        it 'loads team_id from conversation' do
          conversation.update!(team_id: team.id)

          described_class.perform(reporting_event)

          team_row = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'team',
            dimension_id: team.id
          )
          expect(team_row).to be_present
        end
      end

      describe 'upsert behavior' do
        let(:reporting_event) do
          create(:reporting_event,
                 account: account,
                 name: 'conversation_resolved',
                 value: 1000,
                 value_in_business_hours: 500,
                 user: user,
                 inbox: inbox,
                 conversation: conversation)
        end

        it 'increments count and sums on duplicate entries' do
          # First call
          described_class.perform(reporting_event)

          resolution_time = ReportingEventsRollup.find_by(
            account_id: account.id,
            dimension_type: 'account',
            metric: 'resolution_time'
          )
          expect(resolution_time.count).to eq(1)
          expect(resolution_time.sum_value).to eq(1000)
          expect(resolution_time.sum_value_business_hours).to eq(500)

          # Second call with same event
          reporting_event2 = create(:reporting_event,
                                    account: account,
                                    name: 'conversation_resolved',
                                    value: 500,
                                    value_in_business_hours: 250,
                                    user: user,
                                    inbox: inbox,
                                    conversation: conversation,
                                    created_at: reporting_event.created_at)

          described_class.perform(reporting_event2)

          # Total should be incremented
          resolution_time.reload
          expect(resolution_time.count).to eq(2)
          expect(resolution_time.sum_value).to eq(1500)
          expect(resolution_time.sum_value_business_hours).to eq(750)
        end

        it 'does not create duplicate rollup rows' do
          described_class.perform(reporting_event)
          initial_count = ReportingEventsRollup.count

          # Create another event with same date and dimensions
          reporting_event2 = create(:reporting_event,
                                    account: account,
                                    name: 'conversation_resolved',
                                    value: 500,
                                    value_in_business_hours: 250,
                                    user: user,
                                    inbox: inbox,
                                    conversation: conversation,
                                    created_at: reporting_event.created_at)

          described_class.perform(reporting_event2)

          # Row count should remain the same
          expect(ReportingEventsRollup.count).to eq(initial_count)
        end
      end
    end

    context 'unknown event name' do
      let(:reporting_event) do
        create(:reporting_event,
               account: account,
               name: 'unknown_event',
               user: user,
               inbox: inbox,
               conversation: conversation)
      end

      it 'does not create any rollup rows' do
        expect do
          described_class.perform(reporting_event)
        end.not_to change(ReportingEventsRollup, :count)
      end
    end
  end
end
