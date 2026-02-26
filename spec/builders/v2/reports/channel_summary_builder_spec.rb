require 'rails_helper'

RSpec.describe V2::Reports::ChannelSummaryBuilder do
  let!(:account) { create(:account) }
  let!(:web_widget_inbox) { create(:inbox, account: account) }
  let!(:email_inbox) { create(:inbox, :with_email, account: account) }
  let(:params) do
    {
      since: 1.week.ago.beginning_of_day,
      until: Time.current.end_of_day
    }
  end
  let(:builder) { described_class.new(account: account, params: params) }

  describe '#build' do
    subject(:report) { builder.build }

    context 'when there are conversations with different statuses across channels' do
      before do
        # Web widget conversations
        create(:conversation, account: account, inbox: web_widget_inbox, status: :open, created_at: 2.days.ago)
        create(:conversation, account: account, inbox: web_widget_inbox, status: :open, created_at: 3.days.ago)
        create(:conversation, account: account, inbox: web_widget_inbox, status: :resolved, created_at: 2.days.ago)
        create(:conversation, account: account, inbox: web_widget_inbox, status: :pending, created_at: 1.day.ago)
        create(:conversation, account: account, inbox: web_widget_inbox, status: :snoozed, created_at: 1.day.ago)

        # Email conversations
        create(:conversation, account: account, inbox: email_inbox, status: :open, created_at: 2.days.ago)
        create(:conversation, account: account, inbox: email_inbox, status: :resolved, created_at: 1.day.ago)
        create(:conversation, account: account, inbox: email_inbox, status: :resolved, created_at: 3.days.ago)
      end

      it 'returns correct counts grouped by channel type' do
        expect(report['Channel::WebWidget']).to eq(
          open: 2,
          resolved: 1,
          pending: 1,
          snoozed: 1,
          total: 5
        )

        expect(report['Channel::Email']).to eq(
          open: 1,
          resolved: 2,
          pending: 0,
          snoozed: 0,
          total: 3
        )
      end
    end

    context 'when conversations are outside the date range' do
      before do
        create(:conversation, account: account, inbox: web_widget_inbox, status: :open, created_at: 2.days.ago)
        create(:conversation, account: account, inbox: web_widget_inbox, status: :resolved, created_at: 2.weeks.ago)
      end

      it 'only includes conversations within the date range' do
        expect(report['Channel::WebWidget']).to eq(
          open: 1,
          resolved: 0,
          pending: 0,
          snoozed: 0,
          total: 1
        )
      end
    end

    context 'when there are no conversations' do
      it 'returns an empty hash' do
        expect(report).to eq({})
      end
    end

    context 'when a channel has only one status type' do
      before do
        create(:conversation, account: account, inbox: web_widget_inbox, status: :resolved, created_at: 1.day.ago)
        create(:conversation, account: account, inbox: web_widget_inbox, status: :resolved, created_at: 2.days.ago)
      end

      it 'returns zeros for other statuses' do
        expect(report['Channel::WebWidget']).to eq(
          open: 0,
          resolved: 2,
          pending: 0,
          snoozed: 0,
          total: 2
        )
      end
    end
  end
end
