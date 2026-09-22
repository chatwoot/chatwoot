require 'rails_helper'

RSpec.describe ConversationMonitors::Usage do
  subject(:usage) { described_class.new(account_id) }

  let(:account_id) { 123 }
  let(:minute) { Time.current.utc.strftime('%Y%m%d%H%M') }
  let(:day) { Time.current.utc.strftime('%Y%m%d') }
  let(:global_key) { "conversation_monitors:requests:#{minute}" }
  let(:account_key) { "conversation_monitors:account:#{account_id}:requests:#{minute}" }
  let(:token_key) { "conversation_monitors:account:#{account_id}:tokens:#{day}" }

  around do |example|
    travel_to(Time.utc(2026, 9, 22, 12)) do
      with_modified_env(TYPESAFE_REQUESTS_PER_MINUTE: '100', CONVERSATION_MONITORS_DAILY_TOKEN_LIMIT: '1000') { example.run }
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
  end

  it 'does not consume global capacity when the account request allowance is exhausted' do
    Redis::Alfred.setex(account_key, 60, 2.minutes)

    expect { usage.reserve!(100) }.to raise_error(CustomExceptions::MonitorEvaluationError, 'rate_limit')
    expect(Redis::Alfred.get(global_key).to_i).to eq(0)
    expect(Redis::Alfred.get(account_key).to_i).to eq(60)
    expect(Redis::Alfred.get(token_key).to_i).to eq(0)
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
  end
end
