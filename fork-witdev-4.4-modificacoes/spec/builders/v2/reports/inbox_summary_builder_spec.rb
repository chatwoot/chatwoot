require 'rails_helper'

RSpec.describe V2::Reports::InboxSummaryBuilder do
  let(:account) { create(:account) }
  let(:i1) { create(:inbox, account: account) }
  let(:i2) { create(:inbox, account: account) }
  let(:params) do
    {
      business_hours: business_hours,
      since: 1.week.ago.beginning_of_day,
      until: Time.current.end_of_day
    }
  end
  let(:builder) { described_class.new(account: account, params: params) }

  before do
    c1 = create(:conversation, account: account, inbox: i1, created_at: 2.days.ago)
    c2 = create(:conversation, account: account, inbox: i2, created_at: 1.day.ago)
    c2.resolved!
    create(:reporting_event, account: account, conversation: c2, inbox: i2, name: 'conversation_resolved', value: 100, value_in_business_hours: 60,
                             created_at: 1.day.ago)
    create(:reporting_event, account: account, conversation: c1, inbox: i1, name: 'first_response', value: 50, value_in_business_hours: 30,
                             created_at: 1.day.ago)
    create(:reporting_event, account: account, conversation: c1, inbox: i1, name: 'reply_time', value: 30, value_in_business_hours: 10,
                             created_at: 1.day.ago)
    create(:reporting_event, account: account, conversation: c1, inbox: i1, name: 'reply_time', value: 40, value_in_business_hours: 20,
                             created_at: 1.day.ago)
  end

  describe '#build' do
    subject(:report) { builder.build }

    context 'when business hours is disabled' do
      let(:business_hours) { false }

      it 'includes correct stats for each inbox' do
        expect(report).to contain_exactly({
                                            id: i1.id,
                                            conversations_count: 1,
                                            resolved_conversations_count: 0,
                                            avg_resolution_time: nil,
                                            avg_first_response_time: 50.0,
                                            avg_reply_time: 35.0
                                          }, {
                                            id: i2.id,
                                            conversations_count: 1,
                                            resolved_conversations_count: 1,
                                            avg_resolution_time: 100.0,
                                            avg_first_response_time: nil,
                                            avg_reply_time: nil
                                          })
      end
    end

    context 'when business hours is enabled' do
      let(:business_hours) { true }

      it 'uses business hours values for calculations' do
        expect(report).to contain_exactly({
                                            id: i1.id,
                                            conversations_count: 1,
                                            resolved_conversations_count: 0,
                                            avg_resolution_time: nil,
                                            avg_first_response_time: 30.0,
                                            avg_reply_time: 15.0
                                          }, {
                                            id: i2.id,
                                            conversations_count: 1,
                                            resolved_conversations_count: 1,
                                            avg_resolution_time: 60.0,
                                            avg_first_response_time: nil,
                                            avg_reply_time: nil
                                          })
      end
    end

    context 'when there is no data for an inbox' do
      let!(:empty_inbox) { create(:inbox, account: account) }
      let(:business_hours) { false }

      it 'returns nil values for metrics' do
        expect(report).to include(
          id: empty_inbox.id,
          conversations_count: 0,
          resolved_conversations_count: 0,
          avg_resolution_time: nil,
          avg_first_response_time: nil,
          avg_reply_time: nil
        )
      end
    end
  end
end
