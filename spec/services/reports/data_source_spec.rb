require 'rails_helper'

RSpec.describe Reports::DataSource do
  describe '.for' do
    let(:account) { create(:account, reporting_timezone: 'America/New_York') }
    let(:current_offset) { ActiveSupport::TimeZone['America/New_York'].now.utc_offset / 3600.0 }
    let(:params) do
      {
        account: account,
        metric: 'avg_resolution_time',
        dimension_type: 'account',
        dimension_id: nil,
        scope: account,
        range: 1.day.ago.beginning_of_day...Time.current.end_of_day,
        group_by: 'day',
        timezone: 'America/New_York',
        timezone_offset: current_offset,
        business_hours: false
      }
    end

    before do
      allow(account).to receive(:feature_enabled?).with('reporting_events_rollup').and_return(true)
    end

    it 'returns the rollup adapter when the request is eligible' do
      expect(described_class.for(**params)).to be_a(Reports::RollupDataSource)
    end

    it 'falls back to the raw adapter when the feature flag is disabled' do
      allow(account).to receive(:feature_enabled?).with('reporting_events_rollup').and_return(false)

      expect(described_class.for(**params)).to be_a(Reports::RawDataSource)
    end

    it 'falls back to the raw adapter when the reporting timezone is missing' do
      account.update!(reporting_timezone: nil)

      expect(described_class.for(**params)).to be_a(Reports::RawDataSource)
    end

    it 'falls back to the raw adapter when the timezone offset does not match the account' do
      expect(described_class.for(**params, timezone_offset: 0)).to be_a(Reports::RawDataSource)
    end

    it 'falls back to the raw adapter for hourly groupings' do
      expect(described_class.for(**params, group_by: 'hour')).to be_a(Reports::RawDataSource)
    end

    it 'falls back to the raw adapter for unsupported dimensions' do
      expect(described_class.for(**params, dimension_type: 'team')).to be_a(Reports::RawDataSource)
    end

    it 'returns the rollup adapter for summary queries without a metric' do
      expect(described_class.for(**params, metric: nil, dimension_type: 'agent')).to be_a(Reports::RollupDataSource)
    end

    it 'falls back to the raw adapter for raw-only metrics' do
      expect(described_class.for(**params, metric: 'conversations_count')).to be_a(Reports::RawDataSource)
    end
  end
end
