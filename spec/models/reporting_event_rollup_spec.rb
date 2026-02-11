require 'rails_helper'

RSpec.describe ReportingEventsRollup do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'enums' do
    describe 'dimension_type enum' do
      it 'stores dimension_type as string values' do
        rollup = build(:reporting_events_rollup, dimension_type: 'account')
        expect(rollup.dimension_type).to eq('account')
      end

      it 'has account dimension type' do
        rollup = build(:reporting_events_rollup, dimension_type: 'account')
        expect(rollup.account?).to be true
      end

      it 'has agent dimension type' do
        rollup = build(:reporting_events_rollup, dimension_type: 'agent')
        expect(rollup.agent?).to be true
      end

      it 'has inbox dimension type' do
        rollup = build(:reporting_events_rollup, dimension_type: 'inbox')
        expect(rollup.inbox?).to be true
      end

      it 'has team dimension type' do
        rollup = build(:reporting_events_rollup, dimension_type: 'team')
        expect(rollup.team?).to be true
      end
    end

    describe 'metric enum' do
      it 'stores metric as string values' do
        rollup = build(:reporting_events_rollup, metric: 'first_response')
        expect(rollup.metric).to eq('first_response')
      end

      it 'has resolutions_count metric' do
        rollup = build(:reporting_events_rollup, metric: 'resolutions_count')
        expect(rollup.resolutions_count?).to be true
      end

      it 'has first_response metric' do
        rollup = build(:reporting_events_rollup, metric: 'first_response')
        expect(rollup.first_response?).to be true
      end

      it 'has resolution_time metric' do
        rollup = build(:reporting_events_rollup, metric: 'resolution_time')
        expect(rollup.resolution_time?).to be true
      end

      it 'has reply_time metric' do
        rollup = build(:reporting_events_rollup, metric: 'reply_time')
        expect(rollup.reply_time?).to be true
      end

      it 'has bot_resolutions_count metric' do
        rollup = build(:reporting_events_rollup, metric: 'bot_resolutions_count')
        expect(rollup.bot_resolutions_count?).to be true
      end

      it 'has bot_handoffs_count metric' do
        rollup = build(:reporting_events_rollup, metric: 'bot_handoffs_count')
        expect(rollup.bot_handoffs_count?).to be true
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:dimension_type) }
    it { is_expected.to validate_presence_of(:dimension_id) }
    it { is_expected.to validate_presence_of(:metric) }
    it { is_expected.to validate_numericality_of(:count).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:other_account) { create(:account) }

    describe '.for_date_range' do
      it 'filters by date range' do
        create(:reporting_events_rollup, account: account, date: '2026-02-08'.to_date)
        create(:reporting_events_rollup, account: account, date: '2026-02-10'.to_date)
        create(:reporting_events_rollup, account: account, date: '2026-02-12'.to_date)

        results = ReportingEventsRollup.for_date_range('2026-02-10'.to_date, '2026-02-11'.to_date)

        expect(results.count).to eq(1)
        expect(results.first.date).to eq('2026-02-10'.to_date)
      end

      it 'returns empty array when no records match' do
        create(:reporting_events_rollup, account: account, date: '2026-02-08'.to_date)

        results = ReportingEventsRollup.for_date_range('2026-02-20'.to_date, '2026-02-25'.to_date)

        expect(results).to be_empty
      end
    end

    describe '.for_dimension' do
      it 'filters by dimension type and id' do
        create(:reporting_events_rollup, account: account, dimension_type: 'account', dimension_id: 1)
        create(:reporting_events_rollup, account: account, dimension_type: 'agent', dimension_id: 1)
        create(:reporting_events_rollup, account: account, dimension_type: 'agent', dimension_id: 2)

        results = ReportingEventsRollup.for_dimension('agent', 1)

        expect(results.count).to eq(1)
        expect(results.first.dimension_type).to eq('agent')
        expect(results.first.dimension_id).to eq(1)
      end

      it 'returns empty array when no records match' do
        create(:reporting_events_rollup, account: account, dimension_type: 'account', dimension_id: 1)

        results = ReportingEventsRollup.for_dimension('agent', 1)

        expect(results).to be_empty
      end
    end

    describe '.for_metric' do
      it 'filters by metric' do
        create(:reporting_events_rollup, account: account, metric: 'first_response', dimension_id: 1)
        create(:reporting_events_rollup, account: account, metric: 'resolution_time', dimension_id: 2)
        create(:reporting_events_rollup, account: account, metric: 'first_response', dimension_id: 3)

        results = ReportingEventsRollup.for_metric('first_response')

        expect(results.count).to eq(2)
        expect(results.all? { |r| r.metric == 'first_response' }).to be true
      end

      it 'returns empty array when no records match' do
        create(:reporting_events_rollup, account: account, metric: 'first_response')

        results = ReportingEventsRollup.for_metric('resolution_time')

        expect(results).to be_empty
      end
    end
  end

  describe 'database schema' do
    let(:account) { create(:account) }
    let(:rollup) do
      create(:reporting_events_rollup,
             account: account,
             date: '2026-02-10'.to_date,
             dimension_type: 'account',
             metric: 'first_response')
    end

    it 'has all required columns' do
      expect(rollup).to have_attributes(
        account_id: account.id,
        date: '2026-02-10'.to_date,
        dimension_type: 'account',
        dimension_id: 1,
        metric: 'first_response',
        count: 1,
        sum_value: 100.0,
        sum_value_business_hours: 50.0
      )
    end

    it 'stores enum values as strings in database' do
      rollup
      db_record = ReportingEventsRollup.find(rollup.id)
      expect(db_record.dimension_type).to eq('account')
      expect(db_record.metric).to eq('first_response')
    end
  end
end
