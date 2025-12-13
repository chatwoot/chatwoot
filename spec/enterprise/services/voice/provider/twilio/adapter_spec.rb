require 'rails_helper'

describe Voice::Provider::Twilio::Adapter do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account) }
  let(:adapter) { described_class.new(channel) }
  let(:webhook_service) { instance_double(Twilio::VoiceWebhookSetupService, perform: true) }
  let(:calls_double) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallList) }
  let(:call_instance) do
    instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, sid: 'CA123', status: 'queued')
  end
  let(:client_double) { instance_double(Twilio::REST::Client, calls: calls_double) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(webhook_service)
  end

  it 'initiates an outbound call with expected params' do
    with_modified_env FRONTEND_URL: 'https://app.test' do
      allow(calls_double).to receive(:create).and_return(call_instance)

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
end
