require 'rails_helper'

RSpec.describe ConversationMonitors::Buckets do
  let(:zone) { ActiveSupport::TimeZone['America/New_York'] }

  it 'uses 23 hourly buckets on the spring daylight-saving transition' do
    buckets = described_class.new({ since: zone.local(2026, 3, 8).to_i, until: zone.local(2026, 3, 9).to_i,
                                    interval: 'hour', timezone: 'America/New_York' })

    expect(buckets.ranges.size).to eq(23)
    expect(buckets.ranges.map { |range| range.end - range.begin }).to all(eq(3600))
  end

  it 'keeps both occurrences of a repeated hour in separate buckets' do
    buckets = described_class.new({ since: zone.local(2026, 11, 1).to_i, until: zone.local(2026, 11, 2).to_i,
                                    interval: 'hour', timezone: 'America/New_York' })

    expect(buckets.ranges.size).to eq(25)
    expect(buckets.ranges.map(&:begin).uniq.size).to eq(25)
    expect(buckets.ranges.map { |range| range.end - range.begin }).to all(eq(3600))
  end

  it 'aligns six-hour buckets to local midnight in fractional-offset zones' do
    kathmandu = ActiveSupport::TimeZone['Asia/Kathmandu']
    first = kathmandu.local(2026, 9, 22)
    buckets = described_class.new({ since: first.to_i, until: (first + 1.day).to_i, interval: 'six_hours', timezone: 'Asia/Kathmandu' })

    expect(buckets.ranges.map { |range| range.begin.in_time_zone(kathmandu).hour }).to eq([0, 6, 12, 18])
    expect(buckets.ranges.map { |range| range.end - range.begin }).to all(eq(21_600))
  end

  it 'uses half-open ranges clipped to the exact requested window' do
    first = Time.utc(2026, 9, 22, 12, 15)
    last = first + 2.hours
    buckets = described_class.new({ since: first.to_i, until: last.to_i, interval: 'hour', timezone: 'UTC' })

    expect(buckets.ranges.first.begin).to eq(first)
    expect(buckets.ranges.last.end).to eq(last)
    expect(buckets.ranges).to all(be_exclude_end)
    expect(buckets.range_at(first.to_i)).to eq(buckets.ranges.first)
    expect { buckets.range_at(last.to_i) }.to raise_error(CustomExceptions::MonitorParametersError, 'invalid_bucket')
  end

  it 'rejects oversized charts rather than issuing an unbounded aggregation' do
    buckets = described_class.new({ since: 90.days.ago.to_i, until: Time.current.to_i, interval: 'hour', timezone: 'UTC' })

    expect { buckets.ranges }.to raise_error(CustomExceptions::MonitorParametersError, 'too_many_buckets')
  end
end
