require 'rails_helper'

RSpec.describe ConversationMonitors::Report do
  let(:monitor) { create(:conversation_monitor, created_at: 2.days.ago) }

  before do
    travel_to(Time.utc(2026, 9, 24, 12))
    monitor.initial_scan.update!(enumerated_at: 1.day.ago)
  end

  {
    'Pacific Time (US & Canada)' => 'America/Los_Angeles', 'Asia/Kolkata' => 'Asia/Kolkata', nil => 'UTC', '' => 'UTC'
  }.each do |stored, expected|
    it "uses the normalized account timezone when omitted from the request (#{stored.inspect})" do
      monitor.account.update!(reporting_timezone: stored)
      report = described_class.new(monitor, since: 1.day.ago.to_i, until: Time.current.to_i, interval: 'day')

      expect(report.timeseries[:timezone]).to eq(expected)
    end
  end

  it 'uses account-local day boundaries for both the chart and drilldown' do
    monitor.account.update!(reporting_timezone: 'Pacific Time (US & Canada)')
    params = { since: Time.utc(2026, 9, 23, 7).to_i, until: Time.utc(2026, 9, 24, 7).to_i, interval: 'day' }
    report = described_class.new(monitor, params.merge(bucket_start: params[:since]))

    expect(report.timeseries[:buckets]).to contain_exactly(include(start: params[:since], end: params[:until]))
    expect(report.conversations[:meta][:bucket]).to eq(params.slice(:since, :until))
  end

  it 'preserves explicit IANA timezone overrides' do
    monitor.account.update!(reporting_timezone: 'Pacific Time (US & Canada)')
    report = described_class.new(monitor, since: 1.day.ago.to_i, until: Time.current.to_i, interval: 'day', timezone: 'Asia/Tokyo')

    expect(report.timeseries[:timezone]).to eq('Asia/Tokyo')
  end

  it 'continues rejecting explicit Rails timezone aliases' do
    expect do
      described_class.new(monitor, since: 1.day.ago.to_i, until: Time.current.to_i, interval: 'day', timezone: 'Pacific Time (US & Canada)')
    end.to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::MonitorParametersError') })
  end

  it 'marks future buckets as uncovered' do
    report = described_class.new(monitor, since: 1.hour.ago.to_i, until: 1.hour.from_now.to_i, interval: 'hour', timezone: 'UTC')

    expect(report.timeseries[:buckets].pluck(:covered)).to eq([true, false])
  end

  it 'marks a completed bucket as uncovered while eligible work has not produced an evaluation' do
    conversation = create(:conversation, account: monitor.account, created_at: 1.day.ago)
    ConversationMonitors::WorkItem.for_conversation(conversation).request!(activity_at: Time.current)
    report = described_class.new(monitor, since: 1.day.ago.beginning_of_day.to_i, until: Time.current.beginning_of_day.to_i,
                                          interval: 'day', timezone: 'UTC')

    expect(report.timeseries[:buckets]).to contain_exactly(include(count: 0, covered: false))
  end

  it 'does not mark a completed bucket as uncovered for work already evaluated by this monitor' do
    conversation = create(:conversation, account: monitor.account, created_at: 1.day.ago)
    work = ConversationMonitors::WorkItem.for_conversation(conversation)
    work.request!(activity_at: Time.current)
    monitor.evaluations.create!(account: monitor.account, conversation: conversation, status: 'matched', input_revision: work.revision)
    report = described_class.new(monitor, since: 1.day.ago.beginning_of_day.to_i, until: Time.current.beginning_of_day.to_i,
                                          interval: 'day', timezone: 'UTC')

    expect(report.timeseries[:buckets]).to contain_exactly(include(count: 1, covered: true))
  end

  it 'marks an unmatched evaluation as uncovered when newer work is still queued' do
    conversation = create(:conversation, account: monitor.account, created_at: 1.day.ago)
    work = ConversationMonitors::WorkItem.for_conversation(conversation)
    work.request!(activity_at: Time.current)
    monitor.evaluations.create!(account: monitor.account, conversation: conversation, status: 'unmatched', input_revision: work.revision - 1)
    report = described_class.new(monitor, since: 1.day.ago.beginning_of_day.to_i, until: Time.current.beginning_of_day.to_i,
                                          interval: 'day', timezone: 'UTC')

    expect(report.timeseries[:buckets]).to contain_exactly(include(count: 0, covered: false))
  end

  it 'ignores shared work queued for activity before this monitor became active' do
    conversation = create(:conversation, account: monitor.account, created_at: 4.days.ago)
    ConversationMonitors::WorkItem.for_conversation(conversation).request!(activity_at: 3.days.ago)
    report = described_class.new(monitor, since: 4.days.ago.beginning_of_day.to_i, until: 3.days.ago.beginning_of_day.to_i,
                                          interval: 'day', timezone: 'UTC')

    expect(report.timeseries[:buckets]).to contain_exactly(include(count: 0, covered: true))
  end

  it 'preserves historical coverage and marks partial and full post-pause buckets as uncovered' do
    monitor.update!(paused_at: 90.minutes.ago)
    report = described_class.new(monitor, since: 3.hours.ago.to_i, until: Time.current.to_i, interval: 'hour', timezone: 'UTC')

    expect(report.timeseries[:buckets].pluck(:covered)).to eq([true, false, false])
  end
end
