require 'rails_helper'

RSpec.describe Reports::DataSource do
  let(:account) { create(:account, reporting_timezone: 'Etc/UTC') }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:inbox1) { create(:inbox, account: account) }
  let(:inbox2) { create(:inbox, account: account) }
  let(:timezone) { 'UTC' }
  let(:timezone_offset) { '0' }
  let(:current_time) { Time.zone.parse('2026-01-15 10:00:00 UTC') }
  let(:full_range) { Time.zone.parse('2026-01-05 00:00:00 UTC')...Time.zone.parse('2026-01-16 00:00:00 UTC') }
  let(:day_range) { Time.zone.parse('2026-01-14 00:00:00 UTC')...Time.zone.parse('2026-01-16 00:00:00 UTC') }

  before do
    travel_to current_time
    create(:account_user, account: account, user: user1)
    create(:account_user, account: account, user: user2)

    conversation_one = create(
      :conversation,
      account: account,
      inbox: inbox1,
      assignee: user1,
      created_at: Time.zone.parse('2026-01-06 09:00:00 UTC')
    )
    conversation_two = create(
      :conversation,
      account: account,
      inbox: inbox1,
      assignee: user1,
      created_at: Time.zone.parse('2026-01-14 09:00:00 UTC')
    )
    conversation_three = create(
      :conversation,
      account: account,
      inbox: inbox2,
      assignee: user2,
      created_at: Time.zone.parse('2026-01-15 09:00:00 UTC')
    )

    create(:reporting_event,
           name: 'first_response',
           account: account,
           user: user1,
           inbox: inbox1,
           conversation: conversation_one,
           value: 20,
           value_in_business_hours: 10,
           created_at: Time.zone.parse('2026-01-06 10:00:00 UTC'))
    create(:reporting_event,
           name: 'reply_time',
           account: account,
           user: user1,
           inbox: inbox1,
           conversation: conversation_one,
           value: 10,
           value_in_business_hours: 5,
           created_at: Time.zone.parse('2026-01-06 11:00:00 UTC'))
    create(:reporting_event,
           name: 'conversation_resolved',
           account: account,
           user: user1,
           inbox: inbox1,
           conversation: conversation_one,
           value: 100,
           value_in_business_hours: 80,
           created_at: Time.zone.parse('2026-01-06 12:00:00 UTC'))

    create(:reporting_event,
           name: 'first_response',
           account: account,
           user: user1,
           inbox: inbox1,
           conversation: conversation_two,
           value: 40,
           value_in_business_hours: 30,
           created_at: Time.zone.parse('2026-01-14 10:00:00 UTC'))
    create(:reporting_event,
           name: 'reply_time',
           account: account,
           user: user1,
           inbox: inbox1,
           conversation: conversation_two,
           value: 30,
           value_in_business_hours: 20,
           created_at: Time.zone.parse('2026-01-14 11:00:00 UTC'))
    create(:reporting_event,
           name: 'conversation_resolved',
           account: account,
           user: user1,
           inbox: inbox1,
           conversation: conversation_two,
           value: 200,
           value_in_business_hours: 150,
           created_at: Time.zone.parse('2026-01-14 12:00:00 UTC'))

    create(:reporting_event,
           name: 'first_response',
           account: account,
           user: user2,
           inbox: inbox2,
           conversation: conversation_three,
           value: 60,
           value_in_business_hours: 50,
           created_at: Time.zone.parse('2026-01-15 10:00:00 UTC'))
    create(:reporting_event,
           name: 'reply_time',
           account: account,
           user: user2,
           inbox: inbox2,
           conversation: conversation_three,
           value: 50,
           value_in_business_hours: 40,
           created_at: Time.zone.parse('2026-01-15 11:00:00 UTC'))
    create(:reporting_event,
           name: 'conversation_resolved',
           account: account,
           user: user2,
           inbox: inbox2,
           conversation: conversation_three,
           value: 300,
           value_in_business_hours: 250,
           created_at: Time.zone.parse('2026-01-15 12:00:00 UTC'))

    [Date.new(2026, 1, 6), Date.new(2026, 1, 14), Date.new(2026, 1, 15)].each do |date|
      ReportingEvents::BackfillService.backfill_date(account, date)
    end
  end

  shared_examples 'report adapter contract' do |adapter_class|
    context 'with average metrics' do
      subject(:source) do
        adapter_class.new(
          account: account,
          metric: 'avg_first_response_time',
          dimension_type: 'account',
          dimension_id: nil,
          scope: account,
          range: day_range,
          group_by: 'day',
          timezone: timezone,
          timezone_offset: timezone_offset,
          business_hours: business_hours
        )
      end

      let(:business_hours) { false }

      it 'returns the expected aggregate' do
        expect(source.aggregate).to eq(50.0)
      end

      it 'returns the expected day timeseries' do
        expect(source.timeseries).to eq(
          [
            { count: 1, timestamp: Date.new(2026, 1, 14).in_time_zone(timezone).to_i, value: 40.0 },
            { count: 1, timestamp: Date.new(2026, 1, 15).in_time_zone(timezone).to_i, value: 60.0 }
          ]
        )
      end

      context 'when business hours are requested' do
        let(:business_hours) { true }

        it 'returns the business-hours aggregate and timeseries' do
          expect(source.aggregate).to eq(40.0)
          expect(source.timeseries).to eq(
            [
              { count: 1, timestamp: Date.new(2026, 1, 14).in_time_zone(timezone).to_i, value: 30.0 },
              { count: 1, timestamp: Date.new(2026, 1, 15).in_time_zone(timezone).to_i, value: 50.0 }
            ]
          )
        end
      end
    end

    context 'with count metrics' do
      subject(:source) do
        adapter_class.new(
          account: account,
          metric: 'resolutions_count',
          dimension_type: 'agent',
          dimension_id: user1.id,
          scope: user1,
          range: full_range,
          group_by: 'week',
          timezone: timezone,
          timezone_offset: timezone_offset,
          business_hours: false
        )
      end

      it 'returns the expected aggregate' do
        expect(source.aggregate).to eq(2)
      end

      it 'returns the expected week timeseries' do
        expect(source.timeseries).to eq(
          [
            { value: 1, timestamp: Date.new(2026, 1, 4).in_time_zone(timezone).to_i },
            { value: 1, timestamp: Date.new(2026, 1, 11).in_time_zone(timezone).to_i }
          ]
        )
      end
    end

    context 'with summary metrics' do
      subject(:source) do
        adapter_class.new(
          account: account,
          metric: nil,
          dimension_type: 'inbox',
          dimension_id: nil,
          scope: nil,
          range: full_range,
          group_by: 'day',
          timezone: timezone,
          timezone_offset: timezone_offset,
          business_hours: business_hours
        )
      end

      let(:business_hours) { false }

      it 'returns the expected summary shape and values' do
        expect(source.summary).to eq(
          inbox1.id => {
            resolved_conversations_count: 2,
            avg_resolution_time: 150.0,
            avg_first_response_time: 30.0,
            avg_reply_time: 20.0
          },
          inbox2.id => {
            resolved_conversations_count: 1,
            avg_resolution_time: 300.0,
            avg_first_response_time: 60.0,
            avg_reply_time: 50.0
          }
        )
      end

      context 'when business hours are requested' do
        let(:business_hours) { true }

        it 'returns the business-hours summary values' do
          expect(source.summary).to eq(
            inbox1.id => {
              resolved_conversations_count: 2,
              avg_resolution_time: 115.0,
              avg_first_response_time: 20.0,
              avg_reply_time: 12.5
            },
            inbox2.id => {
              resolved_conversations_count: 1,
              avg_resolution_time: 250.0,
              avg_first_response_time: 50.0,
              avg_reply_time: 40.0
            }
          )
        end
      end
    end
  end

  it_behaves_like 'report adapter contract', Reports::RawDataSource
  it_behaves_like 'report adapter contract', Reports::RollupDataSource
end
