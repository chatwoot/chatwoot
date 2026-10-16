require 'rails_helper'

describe ReportingEvents::BackfillService do
  describe '.backfill_date' do
    let(:account) { create(:account, reporting_timezone: 'America/New_York') }
    let(:date) { Date.new(2026, 2, 11) }
    let(:user) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

    it 'treats nil metric values as zero during backfill' do
      reporting_event = create_backfill_event(
        name: 'first_response', value: 100, value_in_business_hours: 50,
        user: user, inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 15)
      )
      # Simulate a legacy row that already exists in the database with nil metrics.
      # rubocop:disable Rails/SkipsModelValidations
      reporting_event.update_columns(value: nil, value_in_business_hours: nil)
      # rubocop:enable Rails/SkipsModelValidations

      expect { described_class.backfill_date(account, date) }.not_to raise_error

      rollup = find_rollup('account', account.id, 'first_response')
      expect(rollup.count).to eq(1)
      expect(rollup.sum_value).to eq(0)
      expect(rollup.sum_value_business_hours).to eq(0)
    end

    context 'when replacing rows fails atomically' do
      before do
        create(
          :reporting_events_rollup,
          account: account, date: date, dimension_type: 'account', dimension_id: account.id,
          metric: 'first_response', count: 7, sum_value: 700, sum_value_business_hours: 350
        )
      end

      it 'preserves existing rollups when building replacement rows fails' do
        service = described_class.new(account, date)
        allow(service).to receive(:build_rollup_rows).and_raise(StandardError, 'boom')

        expect { service.perform }.to raise_error(StandardError, 'boom')

        rollup = find_rollup('account', account.id, 'first_response')
        expect(rollup.count).to eq(7)
        expect(rollup.sum_value).to eq(700)
        expect(rollup.sum_value_business_hours).to eq(350)
      end

      it 'preserves existing rollups when bulk insert fails' do
        create_backfill_event(
          name: 'first_response', value: 100, value_in_business_hours: 50,
          user: user, inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 15)
        )

        service = described_class.new(account, date)
        allow(service).to receive(:bulk_insert_rollups).and_raise(StandardError, 'boom')

        expect { service.perform }.to raise_error(StandardError, 'boom')

        rollup = find_rollup('account', account.id, 'first_response')
        expect(rollup.count).to eq(7)
        expect(rollup.sum_value).to eq(700)
        expect(rollup.sum_value_business_hours).to eq(350)
      end
    end

    context 'when aggregating grouped rows' do
      let(:second_user) { create(:user, account: account) }
      let(:second_inbox) { create(:inbox, account: account) }
      let(:second_conversation) { create(:conversation, account: account, inbox: second_inbox, assignee: second_user) }

      before do
        create_backfill_event(name: 'first_response', value: 100, value_in_business_hours: 60, user: user,
                              inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 14))
        create_backfill_event(name: 'first_response', value: 40, value_in_business_hours: 20, user: user,
                              inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 15))
        create_backfill_event(name: 'conversation_resolved', value: 200, value_in_business_hours: 80, user: second_user,
                              inbox: second_inbox, conversation: second_conversation, created_at: Time.utc(2026, 2, 11, 16))
        create_backfill_event(name: 'reply_time', value: 500, value_in_business_hours: 300, user: user,
                              inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 12, 5))
        described_class.backfill_date(account, date)
      end

      it 'does not instantiate reporting events' do
        reporting_event_instantiations = count_reporting_event_instantiations do
          described_class.backfill_date(account, date)
        end

        expect(reporting_event_instantiations).to eq(0)
      end

      it 'creates the expected number of rollup rows' do
        rollups = ReportingEventsRollup.where(account_id: account.id, date: date)
        # 3 dimensions × first_response + 3 dimensions × resolutions_count + 3 dimensions × resolution_time
        expect(rollups.count).to eq(9)
      end

      it 'aggregates first_response at the account dimension' do
        account_first_response = find_rollup('account', account.id, 'first_response')
        expect(account_first_response.count).to eq(2)
        expect(account_first_response.sum_value).to eq(140)
        expect(account_first_response.sum_value_business_hours).to eq(80)
      end

      it 'aggregates first_response at the agent dimension' do
        agent_first_response = find_rollup('agent', user.id, 'first_response')
        expect(agent_first_response.count).to eq(2)
        expect(agent_first_response.sum_value).to eq(140)
        expect(agent_first_response.sum_value_business_hours).to eq(80)
      end

      it 'aggregates resolution_time at the agent dimension' do
        agent_resolution_time = find_rollup('agent', second_user.id, 'resolution_time')
        expect(agent_resolution_time.count).to eq(1)
        expect(agent_resolution_time.sum_value).to eq(200)
        expect(agent_resolution_time.sum_value_business_hours).to eq(80)
      end

      it 'aggregates first_response at the inbox dimension' do
        inbox_first_response = find_rollup('inbox', inbox.id, 'first_response')
        expect(inbox_first_response.count).to eq(2)
        expect(inbox_first_response.sum_value).to eq(140)
        expect(inbox_first_response.sum_value_business_hours).to eq(80)
      end

      it 'aggregates resolution_time at the inbox dimension' do
        inbox_resolution_time = find_rollup('inbox', second_inbox.id, 'resolution_time')
        expect(inbox_resolution_time.count).to eq(1)
        expect(inbox_resolution_time.sum_value).to eq(200)
        expect(inbox_resolution_time.sum_value_business_hours).to eq(80)
      end
    end

    context 'when deduplicating distinct-count events' do
      let(:second_user) { create(:user, account: account) }
      let(:second_inbox) { create(:inbox, account: account) }
      let(:conversation_b) { create(:conversation, account: account, inbox: inbox, assignee: user) }
      let(:conversation_c) { create(:conversation, account: account, inbox: second_inbox, assignee: second_user) }

      before do
        # Two events for the same conversation — should count as 1
        create_backfill_event(name: 'conversation_bot_handoff', value: 0, value_in_business_hours: 0, user: user,
                              inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 14))
        create_backfill_event(name: 'conversation_bot_handoff', value: 0, value_in_business_hours: 0, user: user,
                              inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 15))
        # Different conversation, same agent/inbox
        create_backfill_event(name: 'conversation_bot_handoff', value: 0, value_in_business_hours: 0, user: user,
                              inbox: inbox, conversation: conversation_b, created_at: Time.utc(2026, 2, 11, 16))
        # Different agent/inbox
        create_backfill_event(name: 'conversation_bot_handoff', value: 0, value_in_business_hours: 0, user: second_user,
                              inbox: second_inbox, conversation: conversation_c, created_at: Time.utc(2026, 2, 11, 17))
        described_class.backfill_date(account, date)
      end

      it 'creates the expected number of rollup rows' do
        rollups = ReportingEventsRollup.where(account_id: account.id, date: date)
        expect(rollups.count).to eq(5)
      end

      it 'counts 3 distinct conversations at the account dimension' do
        expect(find_rollup('account', account.id, 'bot_handoffs_count').count).to eq(3)
      end

      it 'counts distinct conversations per agent' do
        expect(find_rollup('agent', user.id, 'bot_handoffs_count').count).to eq(2)
        expect(find_rollup('agent', second_user.id, 'bot_handoffs_count').count).to eq(1)
      end

      it 'counts distinct conversations per inbox' do
        expect(find_rollup('inbox', inbox.id, 'bot_handoffs_count').count).to eq(2)
        expect(find_rollup('inbox', second_inbox.id, 'bot_handoffs_count').count).to eq(1)
      end
    end

    def create_backfill_event(**attributes)
      create(
        :reporting_event,
        account: account,
        **attributes
      )
    end

    def find_rollup(dimension_type, dimension_id, metric)
      ReportingEventsRollup.find_by!(
        account_id: account.id,
        date: date,
        dimension_type: dimension_type,
        dimension_id: dimension_id,
        metric: metric
      )
    end

    def count_reporting_event_instantiations(&)
      instantiation_count = 0
      subscriber = lambda do |_name, _start, _finish, _id, payload|
        next unless payload[:class_name] == 'ReportingEvent'

        instantiation_count += payload[:record_count]
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'instantiation.active_record', &)

      instantiation_count
    end
  end
end
