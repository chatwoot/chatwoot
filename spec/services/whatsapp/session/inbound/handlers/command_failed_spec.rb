require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::CommandFailed do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:session_id) { channel.provider_config['session_id'] }
  let(:model) { Whatsapp::Session::Model }
  let(:failure) do
    model::Events::CommandFailed.new(command_id: 'cmd-1', command_type: 'session.logout', message_id: nil,
                                     error: model::WireError.new(code: 'not_attempted', message: 'socket busy dialling'))
  end
  let(:event) { model::Event.build(failure, sid: session_id, epoch: 1, seq: 1) }

  after { Redis::Alfred.delete(Whatsapp::Session::TeardownRetry.attempts_key(session_id, 'session.logout')) }

  # The disconnect button tears the session down while the inbox stays, so the answer
  # comes back to an inbox that exists.
  it 'sends again a teardown of a live inbox that the connector never attempted' do
    expect(dispatch).to eq(:handled)

    expect(Whatsapp::Session::TeardownRetryJob).to have_been_enqueued.with(session_id, 'session.logout')
  end

  it 'logs the code the connector sent, not the one it would degrade to' do
    allow(Rails.logger).to receive(:warn)

    dispatch

    expect(Rails.logger).to have_received(:warn).with(a_string_including('session.logout', 'not_attempted'))
  end

  context 'when the inbox belongs to a provider other than the connector' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false)
    end

    it 'leaves it alone, because the connector is the only one that sends this answer' do
      dispatch

      expect(Whatsapp::Session::TeardownRetryJob).not_to have_been_enqueued
    end
  end
end
