require 'rails_helper'

RSpec.describe ConversationMonitors::Usage do
  subject(:usage) { described_class.new(account_id) }

  let(:account_id) { create(:account).id }

  around do |example|
    travel_to(Time.utc(2026, 9, 22, 12)) { example.run }
  end

  it 'counts one provider request against the monthly allowance' do
    usage.reserve!

    expect(ConversationMonitors::DailyUsage.find_by!(account_id: account_id).calls_count).to eq(1)
    expect(usage.snapshot).to include(limit: 10_000_000, used: 1, remaining: 9_999_999, limit_reached: false, limit_reached_at: nil)
  end

  it 'allows calls beyond the former account and installation per-minute limits' do
    601.times { usage.reserve! }

    expect(ConversationMonitors::DailyUsage.find_by!(account_id: account_id).calls_count).to eq(601)
    expect(usage.snapshot).to include(used: 601, remaining: 9_999_399)
  end

  it 'does not charge a failed reservation and allows a later retry' do
    usage.reserve!
    allow(ConversationMonitors::DailyUsage).to receive(:record_call!).and_raise(ActiveRecord::StatementInvalid, 'write failed')

    expect { usage.reserve! }.to(raise_error { |error| expect(error.class.name).to eq('ActiveRecord::StatementInvalid') })
    expect(usage.snapshot[:used]).to eq(1)

    allow(ConversationMonitors::DailyUsage).to receive(:record_call!).and_call_original
    usage.reserve!

    expect(usage.snapshot[:used]).to eq(2)
  end

  it 'rolls back the daily counter when the transaction fails' do
    allow(ConversationMonitors::DailyUsage).to receive(:record_call!).and_wrap_original do |original, *args, **kwargs|
      original.call(*args, **kwargs)
      raise ActiveRecord::StatementInvalid, 'transaction failed'
    end

    expect { usage.reserve! }.to(raise_error { |error| expect(error.class.name).to eq('ActiveRecord::StatementInvalid') })
    expect(ConversationMonitors::DailyUsage.where(account_id: account_id)).not_to exist
  end

  it 'admits the last daily call and blocks further calls until midnight UTC' do
    daily = ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current, calls_count: 499_999)
    usage.reserve!

    expect { usage.reserve! }.to raise_error(CustomExceptions::MonitorEvaluationError) { |error|
      expect(error).to have_attributes(code: 'budget_limit', retry_after: 12.hours.to_i)
    }
    expect(daily.reload).to have_attributes(calls_count: 500_000, limit_reached_at: nil)
    expect(usage.snapshot).to include(used: 500_000, remaining: 9_500_000, limit_reached: false)
  end

  it 'sums daily calls, admits the last credit, and records the timestamp exactly once' do
    (2..20).each do |days_ago|
      ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current - days_ago, calls_count: 500_000)
    end
    ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current - 1, calls_count: 499_999,
                                             limit_reached_at: 1.day.ago)
    monitor = create(:conversation_monitor, account_id: account_id)
    allow(ConversationMonitors::BroadcastJob).to receive(:schedule)

    usage.reserve!

    expect(usage.snapshot).to include(used: 10_000_000, remaining: 0, limit_reached: true, limit_reached_at: Time.current.to_i)
    expect(usage.snapshot[:daily].last(2)).to eq([{ date: '2026-09-21', calls: 499_999 }, { date: '2026-09-22', calls: 1 }])
    expect(ConversationMonitors::BroadcastJob).to have_received(:schedule).with(monitor.id).once
    reached_at = ConversationMonitors::DailyUsage.find_by!(account_id: account_id, usage_date: Date.current).limit_reached_at

    expect { usage.reserve! }.to raise_error(CustomExceptions::MonitorEvaluationError) { |error|
      expect(error).to have_attributes(code: 'monthly_limit', retry_after: (Time.utc(2026, 10, 1) - Time.current).to_i)
    }
    expect(ConversationMonitors::DailyUsage.find_by!(account_id: account_id, usage_date: Date.current))
      .to have_attributes(calls_count: 1, limit_reached_at: reached_at)
  end

  it 'keeps daily history and starts a fresh monthly allowance at midnight UTC' do
    (1..19).each do |days_ago|
      ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current - days_ago, calls_count: 500_000)
    end
    old = ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current, calls_count: 500_000,
                                                   limit_reached_at: Time.current)
    travel_to Time.utc(2026, 10, 1)
    usage.reserve!

    expect(usage.snapshot).to include(used: 1, remaining: 9_999_999, limit_reached: false, limit_reached_at: nil,
                                      period_start: '2026-10-01', resets_at: Time.utc(2026, 11, 1).to_i)
    expect(old.reload.calls_count).to eq(500_000)
    expect(old.limit_reached_at).to be_present
  end

  it 'isolates the monthly allowance and daily records between accounts' do
    other = create(:account)
    (1..19).each do |days_ago|
      ConversationMonitors::DailyUsage.create!(account: other, usage_date: Date.current - days_ago, calls_count: 500_000)
    end
    ConversationMonitors::DailyUsage.create!(account: other, usage_date: Date.current, calls_count: 500_000, limit_reached_at: Time.current)

    usage.reserve!

    expect(usage.snapshot).to include(used: 1, limit_reached: false)
    expect(described_class.new(other.id).snapshot).to include(used: 10_000_000, limit_reached: true)
  end

  it 'starts a fresh daily allowance at midnight UTC while keeping the monthly usage' do
    daily = ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current, calls_count: 500_000)
    expect { usage.reserve! }.to raise_error(CustomExceptions::MonitorEvaluationError, 'budget_limit')
    travel_to Time.utc(2026, 9, 23)
    usage.reserve!

    expect(daily.reload.calls_count).to eq(500_000)
    expect(usage.snapshot).to include(used: 500_001, remaining: 9_499_999, limit_reached: false)
    expect(usage.snapshot[:daily].last).to eq(date: '2026-09-23', calls: 1)
  end
end
