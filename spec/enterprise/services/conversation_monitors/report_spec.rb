require 'rails_helper'

RSpec.describe ConversationMonitors::Report do
  let(:monitor) { create(:conversation_monitor, created_at: 2.days.ago) }

  before do
    travel_to(Time.utc(2026, 9, 24, 12))
    monitor.initial_scan.update!(enumerated_at: 1.day.ago)
  end

  it 'marks future buckets as uncovered' do
    report = described_class.new(monitor, since: 1.hour.ago.to_i, until: 1.hour.from_now.to_i, interval: 'hour', timezone: 'UTC')

    expect(report.timeseries[:buckets].pluck(:covered)).to eq([true, false])
  end

  it 'preserves historical coverage and marks partial and full post-pause buckets as uncovered' do
    monitor.update!(paused_at: 90.minutes.ago)
    report = described_class.new(monitor, since: 3.hours.ago.to_i, until: Time.current.to_i, interval: 'hour', timezone: 'UTC')

    expect(report.timeseries[:buckets].pluck(:covered)).to eq([true, false, false])
  end
end
