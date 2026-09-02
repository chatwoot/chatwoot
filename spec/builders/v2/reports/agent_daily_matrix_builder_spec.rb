require 'rails_helper'

RSpec.describe V2::Reports::AgentDailyMatrixBuilder do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:jason) { create(:user, account: account, name: 'Jason') }
  let!(:alice) { create(:user, account: account, name: 'Alice') }
  let!(:bob) { create(:user, account: account, name: 'Bob') }
  let!(:zoe) { create(:user, account: account, name: 'Zoe') }
  let(:range_start) { Time.utc(2026, 8, 1) }
  let(:range_end) { Time.utc(2026, 8, 5) }
  let(:params) do
    {
      since: range_start.to_i.to_s,
      until: range_end.to_i.to_s,
      timezone_offset: '0'
    }
  end
  let(:builder) { described_class.new(account: account, params: params) }

  before do
    create_list(:reporting_event, 2, account: account, inbox: inbox, user: jason, name: 'conversation_resolved', created_at: Time.utc(2026, 8, 1, 9))
    create(:reporting_event, account: account, inbox: inbox, user: jason, name: 'conversation_resolved', created_at: Time.utc(2026, 8, 3, 9))
    create(:reporting_event, account: account, inbox: inbox, user: alice, name: 'conversation_resolved', created_at: Time.utc(2026, 8, 2, 10))
    create(:reporting_event, account: account, inbox: inbox, user: bob, name: 'conversation_resolved', created_at: Time.utc(2026, 8, 1, 11))
    create(:reporting_event, account: account, inbox: inbox, user: nil, name: 'conversation_resolved', created_at: Time.utc(2026, 8, 2, 12))
  end

  describe '#build' do
    subject(:report) { builder.build }

    it 'sorts agents by total descending, then name ascending' do
      expect(report[:agents]).to eq([
                                      { id: jason.id, name: 'Jason', total: 3 },
                                      { id: alice.id, name: 'Alice', total: 1 },
                                      { id: bob.id, name: 'Bob', total: 1 },
                                      { id: zoe.id, name: 'Zoe', total: 0 }
                                    ])
    end

    it 'includes every day in the range, including days without activity' do
      expect(report[:days]).to eq(%w[2026-08-01 2026-08-02 2026-08-03 2026-08-04])
    end

    it 'puts counts on the matching agent and day' do
      expect(report[:matrix]).to eq([
                                      [2, 0, 1, 0],
                                      [0, 1, 0, 0],
                                      [1, 0, 0, 0],
                                      [0, 0, 0, 0]
                                    ])
    end

    it 'sets each total to the sum of its matrix row' do
      expect(report[:agents].map { |agent| agent[:total] }).to eq(report[:matrix].map(&:sum))
    end

    it 'excludes resolutions without an assigned user' do
      expect(report[:agents].sum { |agent| agent[:total] }).to eq(5)
    end

    it 'includes account users without resolutions with an all-zero row' do
      zoe_index = report[:agents].index { |agent| agent[:id] == zoe.id }

      expect(report[:agents][zoe_index][:total]).to eq(0)
      expect(report[:matrix][zoe_index]).to eq([0, 0, 0, 0])
    end

    it 'groups counts with user id first and date second in the key' do
      grouped_counts = account.reporting_events
                              .where(name: 'conversation_resolved', created_at: builder.range)
                              .group(:user_id)
                              .group_by_period(:day, :created_at, time_zone: 'UTC')
                              .count

      expect(grouped_counts.keys).to include([jason.id, Date.new(2026, 8, 1)])
      expect(grouped_counts[[jason.id, Date.new(2026, 8, 1)]]).to eq(2)
    end
  end

  context 'when the date range is missing' do
    let(:params) { { timezone_offset: '0' } }

    it 'returns an empty report' do
      expect(builder.build).to eq(agents: [], days: [], matrix: [])
    end
  end
end
