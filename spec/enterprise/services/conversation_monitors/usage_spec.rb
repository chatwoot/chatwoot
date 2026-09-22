require 'rails_helper'

RSpec.describe ConversationMonitors::Usage do
  subject(:usage) { described_class.new(account_id) }

  let(:account_id) { create(:account).id }
  let(:minute) { Time.current.utc.strftime('%Y%m%d%H%M') }
  let(:day) { Time.current.utc.strftime('%Y%m%d') }
  let(:global_key) { "conversation_monitors:requests:#{minute}" }
  let(:account_key) { "conversation_monitors:account:#{account_id}:requests:#{minute}" }
  let(:token_key) { "conversation_monitors:account:#{account_id}:tokens:#{day}" }

  around do |example|
    travel_to(Time.utc(2026, 9, 22, 12)) do
      with_modified_env(CONVERSATION_MONITORS_REQUESTS_PER_MINUTE: '100', CONVERSATION_MONITORS_DAILY_TOKEN_LIMIT: '1000') { example.run }
    end
  end

  before { [global_key, account_key, token_key].each { |key| Redis::Alfred.delete(key) } }
  after { [global_key, account_key, token_key].each { |key| Redis::Alfred.delete(key) } }

  it 'reserves one request and reconciles its token usage' do
    usage.reserve!(100)
    usage.reconcile!(100, 20)

    expect(Redis::Alfred.get(global_key).to_i).to eq(1)
    expect(Redis::Alfred.get(account_key).to_i).to eq(1)
    expect(Redis::Alfred.get(token_key).to_i).to eq(20)
    expect(Redis::Alfred.ttl(token_key)).to be_positive
    expect(ConversationMonitors::DailyUsage.find_by!(account_id: account_id).calls_count).to eq(1)
    expect(usage.snapshot).to include(limit: 100_000, used: 1, remaining: 99_999, limit_reached: false, limit_reached_at: nil)
  end

  it 'does not consume global capacity when the account request allowance is exhausted' do
    Redis::Alfred.setex(account_key, 60, 2.minutes)

    expect { usage.reserve!(100) }.to raise_error(CustomExceptions::MonitorEvaluationError, 'rate_limit')
    expect(Redis::Alfred.get(global_key).to_i).to eq(0)
    expect(Redis::Alfred.get(account_key).to_i).to eq(60)
    expect(Redis::Alfred.get(token_key).to_i).to eq(0)
    expect(ConversationMonitors::DailyUsage.where(account_id: account_id)).not_to exist
  end

  it 'does not consume either request allowance when the token budget is exhausted' do
    Redis::Alfred.setex(token_key, 1000, 2.days)

    expect { usage.reserve!(1) }.to raise_error(CustomExceptions::MonitorEvaluationError, 'budget_limit')
    expect(Redis::Alfred.get(global_key).to_i).to eq(0)
    expect(Redis::Alfred.get(account_key).to_i).to eq(0)
    expect(Redis::Alfred.get(token_key).to_i).to eq(1000)
  end

  it 'does not charge the account when the installation is full' do
    Redis::Alfred.setex(global_key, 100, 2.minutes)

    expect { usage.reserve!(100) }.to raise_error(CustomExceptions::MonitorEvaluationError, 'rate_limit')
    expect(Redis::Alfred.get(global_key).to_i).to eq(100)
    expect(Redis::Alfred.get(account_key).to_i).to eq(0)
    expect(Redis::Alfred.get(token_key).to_i).to eq(0)
    expect(ConversationMonitors::DailyUsage.where(account_id: account_id)).not_to exist
  end

  it 'sums daily calls, admits the last credit, and records the timestamp exactly once' do
    ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current - 1, calls_count: 99_999)
    monitor = create(:conversation_monitor, account_id: account_id)
    allow(ConversationMonitors::BroadcastJob).to receive(:schedule)

    usage.reserve!(10)

    expect(usage.snapshot).to include(used: 100_000, remaining: 0, limit_reached: true, limit_reached_at: Time.current.to_i)
    expect(usage.snapshot[:daily].last(2)).to eq([{ date: '2026-09-21', calls: 99_999 }, { date: '2026-09-22', calls: 1 }])
    expect(ConversationMonitors::BroadcastJob).to have_received(:schedule).with(monitor.id).once
    reached_at = ConversationMonitors::DailyUsage.find_by!(account_id: account_id, usage_date: Date.current).limit_reached_at

    expect { usage.reserve!(10) }.to raise_error(CustomExceptions::MonitorEvaluationError) { |error|
      expect(error).to have_attributes(code: 'monthly_limit', retry_after: (Time.utc(2026, 10, 1) - Time.current).to_i)
    }
    expect(Redis::Alfred.get(global_key).to_i).to eq(1)
    expect(ConversationMonitors::DailyUsage.find_by!(account_id: account_id, usage_date: Date.current))
      .to have_attributes(calls_count: 1, limit_reached_at: reached_at)
  end

  it 'keeps daily history and starts a fresh monthly allowance at midnight UTC' do
    old = ConversationMonitors::DailyUsage.create!(account_id: account_id, usage_date: Date.current, calls_count: 100_000,
                                                   limit_reached_at: Time.current)
    travel_to Time.utc(2026, 10, 1)
    usage.reserve!(10)

    expect(usage.snapshot).to include(used: 1, remaining: 99_999, limit_reached: false, limit_reached_at: nil,
                                      period_start: '2026-10-01', resets_at: Time.utc(2026, 11, 1).to_i)
    expect(old.reload.calls_count).to eq(100_000)
    expect(old.limit_reached_at).to be_present
  end

  it 'isolates the monthly allowance and daily records between accounts' do
    other = create(:account)
    ConversationMonitors::DailyUsage.create!(account: other, usage_date: Date.current, calls_count: 100_000, limit_reached_at: Time.current)

    usage.reserve!(10)

    expect(usage.snapshot).to include(used: 1, limit_reached: false)
    expect(described_class.new(other.id).snapshot).to include(used: 100_000, limit_reached: true)
  end

  it 'reconciles a request to its reserved UTC day even if it finishes after midnight' do
    usage.reserve!(100)
    travel 1.day
    usage.reconcile!(100, 20)

    expect(Redis::Alfred.get(token_key).to_i).to eq(20)
    expect(ConversationMonitors::DailyUsage.find_by!(account_id: account_id).usage_date).to eq(Date.new(2026, 9, 22))
  end
end
