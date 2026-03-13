require 'rails_helper'

describe ReportingEvents::BackfillService do
  describe '.backfill_date' do
    let(:account) { create(:account, reporting_timezone: 'America/New_York') }
    let(:date) { Date.new(2026, 2, 11) }
    let(:user) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

    it 'treats nil metric values as zero during backfill' do
      reporting_event = create(
        :reporting_event,
        account: account,
        name: 'first_response',
        value: 100,
        value_in_business_hours: 50,
        user: user,
        inbox: inbox,
        conversation: conversation,
        created_at: Time.utc(2026, 2, 11, 15)
      )
      # Simulate a legacy row that already exists in the database with nil metrics.
      # rubocop:disable Rails/SkipsModelValidations
      reporting_event.update_columns(value: nil, value_in_business_hours: nil)
      # rubocop:enable Rails/SkipsModelValidations

      expect do
        described_class.backfill_date(account, date)
      end.not_to raise_error

      rollup = ReportingEventsRollup.find_by!(
        account_id: account.id,
        date: date,
        dimension_type: 'account',
        dimension_id: account.id,
        metric: 'first_response'
      )

      expect(rollup.count).to eq(1)
      expect(rollup.sum_value).to eq(0)
      expect(rollup.sum_value_business_hours).to eq(0)
    end

    it 'aggregates grouped rows without instantiating reporting events' do
      second_user = create(:user, account: account)
      second_inbox = create(:inbox, account: account)
      second_conversation = create(:conversation, account: account, inbox: second_inbox, assignee: second_user)

      create_backfill_event(name: 'first_response', value: 100, value_in_business_hours: 60, user: user,
                            inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 14))
      create_backfill_event(name: 'first_response', value: 40, value_in_business_hours: 20, user: user,
                            inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 11, 15))
      create_backfill_event(name: 'conversation_resolved', value: 200, value_in_business_hours: 80, user: second_user,
                            inbox: second_inbox, conversation: second_conversation, created_at: Time.utc(2026, 2, 11, 16))
      create_backfill_event(name: 'reply_time', value: 500, value_in_business_hours: 300, user: user,
                            inbox: inbox, conversation: conversation, created_at: Time.utc(2026, 2, 12, 5))

      reporting_event_instantiations = count_reporting_event_instantiations do
        described_class.backfill_date(account, date)
      end

      expect(reporting_event_instantiations).to eq(0)

      first_response_rollup = find_rollup('agent', user.id, 'first_response')
      expect(first_response_rollup.count).to eq(2)
      expect(first_response_rollup.sum_value).to eq(140)
      expect(first_response_rollup.sum_value_business_hours).to eq(80)

      resolution_time_rollup = find_rollup('agent', second_user.id, 'resolution_time')
      expect(resolution_time_rollup.count).to eq(1)
      expect(resolution_time_rollup.sum_value).to eq(200)
      expect(resolution_time_rollup.sum_value_business_hours).to eq(80)
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
