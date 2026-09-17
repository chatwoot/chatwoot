require 'rails_helper'

describe Auth::SignInAbuseTracker do
  subject(:tracker) { described_class.new(ip: ip) }

  let(:ip) { '203.0.113.10' }
  let(:zset_key) { format(Redis::RedisKeys::AUTH_FAILED_EMAILS_PER_IP, ip: ip) }
  let(:block_key) { format(Redis::RedisKeys::AUTH_ABUSE_BLOCKED_IP, ip: ip) }

  before do
    GlobalConfig.clear_cache
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    Redis::Alfred.delete(zset_key)
    Redis::Alfred.delete(block_key)
  end

  after { GlobalConfig.clear_cache }

  it 'does not block below the distinct-email threshold' do
    4.times { |i| tracker.record_failure("u#{i}@example.com") }

    expect(tracker.blocked?).to be false
  end

  it 'blocks after the threshold of distinct failed emails' do
    5.times { |i| tracker.record_failure("u#{i}@example.com") }

    expect(tracker.blocked?).to be true
    expect(Redis::Alfred.ttl(block_key)).to be_between(1, described_class::BLOCK_TTL.to_i)
  end

  it 'counts repeated failures for one email once' do
    10.times { tracker.record_failure('a@example.com') }

    expect(tracker.blocked?).to be false
  end

  it 'prunes failures older than the window' do
    stale_score = described_class::WINDOW.ago.to_i - 60
    4.times do |i|
      Redis::Alfred.zadd(zset_key, stale_score, Digest::SHA256.hexdigest("old#{i}@example.com"))
    end

    tracker.record_failure('fresh@example.com')

    expect(tracker.blocked?).to be false
  end

  it 'normalizes email case and whitespace' do
    tracker.record_failure(' A@Example.com ')
    tracker.record_failure('a@example.com')

    expect(Redis::Alfred.zcard(zset_key)).to eq(1)
  end

  it 'stores digests, not raw emails' do
    tracker.record_failure('a@example.com')

    members = Redis::Alfred.zrangebyscore(zset_key, 0, Time.zone.now.to_i + 1)
    expect(members).to eq([Digest::SHA256.hexdigest('a@example.com')])
  end

  it 'never blocks trusted ips' do
    trusted = described_class.new(ip: '127.0.0.1')

    8.times { |i| trusted.record_failure("u#{i}@example.com") }

    expect(trusted.blocked?).to be false
  end

  it 'honors the rack attack allowed ips list' do
    with_modified_env('RACK_ATTACK_ALLOWED_IPS' => "10.0.0.5, #{ip}") do
      8.times { |i| tracker.record_failure("u#{i}@example.com") }

      expect(tracker.blocked?).to be false
    end
  end

  it 'does nothing when the kill switch is off' do
    allow(GlobalConfigService).to receive(:load)
      .with('AUTH_ABUSE_IP_BLOCKING_ENABLED', anything).and_return('false')

    8.times { |i| tracker.record_failure("u#{i}@example.com") }

    expect(tracker.blocked?).to be false
  end

  it 'is off by default outside cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

    8.times { |i| tracker.record_failure("u#{i}@example.com") }

    expect(tracker.blocked?).to be false
  end

  it 'logs a warn line once when the block is set' do
    allow(Rails.logger).to receive(:warn).and_call_original

    7.times { |i| tracker.record_failure("u#{i}@example.com") }

    expect(Rails.logger).to have_received(:warn).with(/\[AuthAbuse\]\[IPBlocked\] remote_ip: #{ip}/).once
  end
end
