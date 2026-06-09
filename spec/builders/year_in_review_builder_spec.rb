require 'rails_helper'

RSpec.describe YearInReviewBuilder, type: :model do
  subject(:builder) { described_class.new(account: account, user_id: user.id, year: year) }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:year) { 2025 }

  describe '#build' do
    context 'when there is no data for the year' do
      it 'returns empty aggregates' do
        result = builder.build

        expect(result[:year]).to eq(year)
        expect(result[:total_conversations]).to eq(0)
        expect(result[:busiest_day]).to be_nil
        expect(result[:support_personality]).to eq({ avg_response_time_seconds: 0 })
      end
    end

    context 'when there is data for the year' do
      let(:busiest_date) { Time.zone.local(year, 3, 10, 10, 0, 0) }
      let(:other_date) { Time.zone.local(year, 3, 11, 10, 0, 0) }

      before do
        create(:conversation, account: account, assignee: user, created_at: busiest_date)
        create(:conversation, account: account, assignee: user, created_at: busiest_date + 1.hour)
        create(:conversation, account: account, assignee: user, created_at: other_date)

        create(
          :reporting_event,
          account: account,
          user: user,
          name: 'first_response',
          value: 12.7,
          created_at: busiest_date
        )
      end

      it 'returns total conversations count' do
        expect(builder.build[:total_conversations]).to eq(3)
      end

      it 'returns busiest day data' do
        expect(builder.build[:busiest_day]).to eq({ date: busiest_date.strftime('%b %d'), count: 2 })
      end

      it 'returns support personality data' do
        expect(builder.build[:support_personality]).to eq({ avg_response_time_seconds: 12 })
      end

      it 'scopes data to the provided year' do
        create(:conversation, account: account, assignee: user, created_at: Time.zone.local(year - 1, 6, 1))
        create(:reporting_event, account: account, user: user, name: 'first_response', value: 99, created_at: Time.zone.local(year - 1, 6, 1))

        result = builder.build

        expect(result[:total_conversations]).to eq(3)
        expect(result[:support_personality]).to eq({ avg_response_time_seconds: 12 })
      end
    end
  end
end
