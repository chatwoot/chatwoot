require 'rails_helper'

RSpec.describe Whatsapp::Session::TeardownRetryJob, :redis_streams do
  let(:prefix) { "watest#{SecureRandom.hex(4)}:" }
  let(:redis) { Redis.new(Redis::Config.app) }
  let(:session_id) { SecureRandom.uuid }

  around do |example|
    with_modified_env(WHATSAPP_CONNECTOR_REDIS_PREFIX: prefix) { example.run }
    keys = redis.keys("#{prefix}*")
    redis.del(*keys) if keys.any?
  end

  def frames(stream)
    redis.xrange("#{prefix}#{stream}").map(&:last)
  end

  context 'when no inbox holds the session any more' do
    # The inbox was destroyed or moved to another provider: the teardown is the last thing
    # anybody will ever ask of this session, so nothing stands in its way.
    it 'sends the delete again on the control stream, bounded by runtime and never by a deadline' do
      described_class.perform_now(session_id, 'session.delete')

      sent = frames('control')
      expect(sent.size).to eq(1)
      expect(sent.first).to include('type' => 'session.delete', 'sid' => session_id)
      expect(sent.first['deadline']).to be_nil
      expect(sent.first['max_runtime_ms']).to eq((Whatsapp::Session::Backends::Connector::Backend::TEARDOWN_RUNTIME * 1000).to_s)
    end

    it "sends the logout again on the session's own stream" do
      described_class.perform_now(session_id, 'session.logout')

      sent = frames("cmd:#{session_id}")
      expect(sent.size).to eq(1)
      expect(sent.first).to include('type' => 'session.logout', 'sid' => session_id)
      expect(sent.first['deadline']).to be_nil
    end
  end

  context 'when the inbox is still there' do
    let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:session_id) { channel.provider_config['session_id'] }

    after { Whatsapp::Session::TeardownRetry.withdrawn(session_id) }

    # The operator disconnected it and nobody asked to connect it since: the teardown is
    # still what the inbox wants.
    it 'sends it again while the teardown it asked for stands' do
      Whatsapp::Session::TeardownRetry.requested(session_id)

      described_class.perform_now(session_id, 'session.delete')

      expect(frames('control').size).to eq(1)
    end

    # The connection record cannot say this: a dropped connection writes `close` too, and a
    # retry keyed on it would end a session the operator had just paired again.
    it 'stands down once somebody asked to connect it again, whatever the connection reads' do
      Whatsapp::Session::TeardownRetry.requested(session_id)
      Whatsapp::Session::TeardownRetry.withdrawn(session_id)
      channel.update_provider_connection!({ 'connection' => 'close' })

      described_class.perform_now(session_id, 'session.delete')

      expect(frames('control')).to be_empty
    end

    # A logout the LogoutJob sent to a quarantined account is that job's to repeat, on its
    # own schedule and behind its own check; nothing here asked for a teardown.
    it 'sends nothing for an inbox that never asked for a teardown' do
      channel.update_provider_connection!({ 'connection' => 'close', 'error_code' => 'wrong_phone_number' })

      described_class.perform_now(session_id, 'session.logout')

      expect(frames("cmd:#{session_id}")).to be_empty
    end
  end
end
