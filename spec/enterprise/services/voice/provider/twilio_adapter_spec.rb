require 'rails_helper'

describe Voice::Provider::TwilioAdapter do
  before { allow_any_instance_of(Channel::Voice).to receive(:provision_twilio_on_create).and_return(true) }

  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account) }
  let(:adapter) { described_class.new(channel) }

  it 'initiates an outbound call with expected params' do
    allow(ENV).to receive(:fetch).with('FRONTEND_URL').and_return('https://app.test')

    calls_double = double('calls')
    allow(calls_double).to receive(:create).and_return(
      double('call', sid: 'CA123', status: 'queued')
    )

    client_double = double('twilio_client', calls: calls_double)
    allow(Twilio::REST::Client).to receive(:new)
      .with(channel.provider_config_hash['account_sid'], channel.provider_config_hash['auth_token'])
      .and_return(client_double)

    result = adapter.initiate_call(to: '+15550001111', conference_sid: 'CF999', agent_id: 42)

    expect(calls_double).to have_received(:create).with(hash_including(
                                                          from: channel.phone_number,
                                                          to: '+15550001111',
                                                          url: "https://app.test/twilio/voice/call/#{channel.phone_number.delete_prefix('+')}",
                                                          status_callback: "https://app.test/twilio/voice/status/#{channel.phone_number.delete_prefix('+')}",
                                                          status_callback_event: array_including('completed', 'failed', 'busy', 'no-answer',
                                                                                                 'canceled')
                                                        ))
    expect(result[:call_sid]).to eq('CA123')
    expect(result[:conference_sid]).to eq('CF999')
    expect(result[:agent_id]).to eq(42)
    expect(result[:call_direction]).to eq('outbound')
  end
end
