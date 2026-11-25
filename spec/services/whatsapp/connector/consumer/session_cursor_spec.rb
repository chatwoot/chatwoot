require 'rails_helper'

RSpec.describe Whatsapp::Connector::Consumer::SessionCursor, :redis_streams do
  subject(:cursor) { described_class.new(redis) }

  let(:prefix) { "watest#{SecureRandom.hex(4)}:" }
  let(:redis) { Redis.new(Redis::Config.app) }
  let(:session_id) { '9f1c0f4e-6a2b-4c8e-9d1a-2b3c4d5e6f70' }

  around do |example|
    with_modified_env(WHATSAPP_CONNECTOR_REDIS_PREFIX: prefix) { example.run }
    keys = redis.keys("#{prefix}*")
    redis.del(*keys) if keys.any?
  end

  def event_at(epoch, seq)
    Whatsapp::Session::Model::Event.build(
      Whatsapp::Session::Model::Events::SessionLoggedOut.new,
      sid: session_id, epoch: epoch, seq: seq
    )
  end

  it 'takes anything while the session has no cursor' do
    expect(cursor).to be_behind(event_at(1, 1))
  end

  it 'is behind an event past the position it holds, and not behind one before it' do
    cursor.advance(event_at(2, 5))

    expect(cursor).to be_behind(event_at(2, 6))
    expect(cursor).not_to be_behind(event_at(2, 5))
    expect(cursor).not_to be_behind(event_at(2, 4))
  end

  # A shard count change is the one time two workers can hold the same session, and the
  # one reading the older stream would otherwise put the cursor back, after which
  # everything between would be dispatched a second time.
  it 'refuses to go backwards' do
    cursor.advance(event_at(2, 5))

    cursor.advance(event_at(2, 3))

    expect(redis.get("#{prefix}cursor:#{session_id}")).to eq('2:5')
  end

  it 'refuses to go back an epoch' do
    cursor.advance(event_at(3, 1))

    cursor.advance(event_at(2, 99))

    expect(redis.get("#{prefix}cursor:#{session_id}")).to eq('3:1')
  end

  # Two numbers, not a string: "10:1" sorts before "9:1" lexically.
  it 'compares the position numerically' do
    cursor.advance(event_at(9, 1))

    cursor.advance(event_at(10, 1))

    expect(redis.get("#{prefix}cursor:#{session_id}")).to eq('10:1')
  end

  it 'expires so a deleted inbox leaves nothing behind' do
    cursor.advance(event_at(1, 1))

    expect(redis.ttl("#{prefix}cursor:#{session_id}")).to be_between(1, described_class::TTL)
  end
end
