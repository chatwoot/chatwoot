require 'rails_helper'

# {
#   id: 'id of the object'
#   type: 'account/inbox/labels/team'
#   business_hours: boolean,
#   timezone_offset: number,
#   group_by: 'day/week/month/year',
#   metric: ''
# }

describe V2::Reports::Timeseries::AverageReportBuilder do
  subject { described_class.new(account, params) }

  let(:account) { create(:account) }
  let(:params) do
    {
      type: :account,
      business_hours: business_hours,
      timezone_offset: timezone_offset,
      group_by: group_by,
      metric: metric,
      since: from,
      until: to,
      id: filter_object_id
    }
  end
  let(:timezone_offset) { 0 }
  let(:group_by) { 'day' }
  let(:metric) { 'avg_first_response_time' }
  let(:business_hours) { false }
  let(:current_time) { '26.10.2020 10:00'.to_datetime }
  let(:from) { (current_time - 1.week).beginning_of_day.to_i.to_s }
  let(:to) { current_time.end_of_day.to_i.to_s }
  let(:filter_object_id) { current_time.end_of_day.to_i.to_s }

  describe '#timeseries' do
    before do
      travel_to current_time
      create(:reporting_event, name: 'first_response', value: 80, value_in_business_hours: 10, account: account, created_at: Time.zone.now)
      create(:reporting_event, name: 'first_response', value: 100, value_in_business_hours: 20, account: account, created_at: 1.hour.ago, inbox_id: 2)
      create(:reporting_event, name: 'first_response', value: 100, value_in_business_hours: 30, account: account, created_at: 1.week.ago)
      create(:reporting_event, name: 'first_response', value: 100, value_in_business_hours: 20, account: account, created_at: 1.month.ago)
    end

    context 'when there is no filter applied' do
      it 'returns the correct values' do
        timeseries_values = subject.timeseries

        expect(timeseries_values).to eq(
          [
            { count: 1, timestamp: 1_603_065_600, value: 100.0 },
            { count: 0, timestamp: 1_603_152_000, value: 0 },
            { count: 0, timestamp: 1_603_238_400, value: 0 },
            { count: 0, timestamp: 1_603_324_800, value: 0 },
            { count: 0, timestamp: 1_603_411_200, value: 0 },
            { count: 0, timestamp: 1_603_497_600, value: 0 },
            { count: 0, timestamp: 1_603_584_000, value: 0 },
            { count: 2, timestamp: 1_603_670_400, value: 90.0 }
          ]
        )
      end

      context 'when business hours is provided' do
        let(:business_hours) { true }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries

          expect(timeseries_values).to eq(
            [
              { count: 1, timestamp: 1_603_065_600, value: 30.0 },
              { count: 0, timestamp: 1_603_152_000, value: 0 },
              { count: 0, timestamp: 1_603_238_400, value: 0 },
              { count: 0, timestamp: 1_603_324_800, value: 0 },
              { count: 0, timestamp: 1_603_411_200, value: 0 },
              { count: 0, timestamp: 1_603_497_600, value: 0 },
              { count: 0, timestamp: 1_603_584_000, value: 0 },
              { count: 2, timestamp: 1_603_670_400, value: 15.0 }
            ]
          )
        end
      end

      context 'when group_by is provided' do
        let(:group_by) { 'week' }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          expect(timeseries_values).to eq(
            [
              { count: 1, timestamp: (current_time - 1.week).beginning_of_week(:sunday).to_i, value: 100.0 },
              { count: 2, timestamp: current_time.beginning_of_week(:sunday).to_i, value: 90.0 }
            ]
          )
        end
      end

      context 'when timezone offset is provided' do
        let(:timezone_offset) { '5.5' }
        let(:group_by) { 'week' }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          expect(timeseries_values).to eq(
            [
              { count: 1, timestamp: (current_time - 1.week).in_time_zone('Chennai').beginning_of_week(:sunday).to_i, value: 100.0 },
              { count: 2, timestamp: current_time.in_time_zone('Chennai').beginning_of_week(:sunday).to_i, value: 90.0 }
            ]
          )
        end
      end
    end

    # context 'where there is inbox filter applied' do
    #   it 'returns correct timeseries' do
    #   end
    # end

    # context 'where there is labels filter applied' do
    #   it 'returns correct timeseries' do
    #   end
    # end

    # context 'where there is team filter applied' do
    #   it 'returns correct timeseries' do
    #   end
    # end
  end
end
