require 'rails_helper'

RSpec.describe V2::Reports::FirstResponseTimeDistributionBuilder do
  let!(:account) { create(:account) }
  let!(:web_widget_inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let!(:email_inbox) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:params) do
    {
      since: 1.week.ago.beginning_of_day.to_i.to_s,
      until: Time.current.end_of_day.to_i.to_s
    }
  end
  let(:builder) { described_class.new(account: account, params: params) }

  describe '#build' do
    subject(:report) { builder.build }

    context 'when there are first response events across channels and time buckets' do
      before do
        # Web Widget: 0-1h bucket (30 minutes = 1800 seconds)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.days.ago)
        # Web Widget: 1-4h bucket (2 hours = 7200 seconds)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 7_200, created_at: 2.days.ago)
        # Web Widget: 4-8h bucket (6 hours = 21600 seconds)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 21_600, created_at: 3.days.ago)
        # Email: 8-24h bucket (12 hours = 43200 seconds)
        create(:reporting_event, account: account, inbox: email_inbox, name: 'first_response',
                                 value: 43_200, created_at: 2.days.ago)
        # Email: 24h+ bucket (48 hours = 172800 seconds)
        create(:reporting_event, account: account, inbox: email_inbox, name: 'first_response',
                                 value: 172_800, created_at: 1.day.ago)
      end

      it 'returns correct distribution for web widget channel' do
        expect(report['Channel::WebWidget']).to eq({
                                                     '0-1h' => 1,
                                                     '1-4h' => 1,
                                                     '4-8h' => 1,
                                                     '8-24h' => 0,
                                                     '24h+' => 0
                                                   })
      end

      it 'returns correct distribution for email channel' do
        expect(report['Channel::Email']).to eq({
                                                 '0-1h' => 0,
                                                 '1-4h' => 0,
                                                 '4-8h' => 0,
                                                 '8-24h' => 1,
                                                 '24h+' => 1
                                               })
      end
    end

    context 'when filtering by date range' do
      before do
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.days.ago)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.weeks.ago)
      end

      it 'only counts events within the date range' do
        expect(report['Channel::WebWidget']['0-1h']).to eq(1)
      end
    end

    context 'when there are no first response events' do
      it 'returns an empty hash' do
        expect(report).to eq({})
      end
    end

    context 'when events belong to another account' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }

      before do
        create(:reporting_event, account: other_account, inbox: other_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.days.ago)
      end

      it 'does not include events from other accounts' do
        expect(report).to eq({})
      end
    end

    context 'when events have different names' do
      before do
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.days.ago)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'conversation_resolved',
                                 value: 1_800, created_at: 2.days.ago)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'reply_time',
                                 value: 1_800, created_at: 2.days.ago)
      end

      it 'only counts first_response events' do
        expect(report['Channel::WebWidget']['0-1h']).to eq(1)
      end
    end

    context 'when no date range params are provided' do
      let(:params) { {} }

      before do
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.days.ago)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 1_800, created_at: 2.months.ago)
      end

      it 'returns all events without date filtering' do
        expect(report['Channel::WebWidget']['0-1h']).to eq(2)
      end
    end

    context 'with boundary values for time buckets' do
      before do
        # Exactly at 1 hour boundary (should be in 1-4h bucket)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 3_600, created_at: 2.days.ago)
        # Just under 1 hour (should be in 0-1h bucket)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 3_599, created_at: 2.days.ago)
        # Exactly at 24 hour boundary (should be in 24h+ bucket)
        create(:reporting_event, account: account, inbox: web_widget_inbox, name: 'first_response',
                                 value: 86_400, created_at: 2.days.ago)
      end

      it 'correctly assigns boundary values to buckets' do
        expect(report['Channel::WebWidget']).to eq({
                                                     '0-1h' => 1,
                                                     '1-4h' => 1,
                                                     '4-8h' => 0,
                                                     '8-24h' => 0,
                                                     '24h+' => 1
                                                   })
      end
    end
  end
end
