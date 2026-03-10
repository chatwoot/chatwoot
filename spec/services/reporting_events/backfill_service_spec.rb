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
  end
end
