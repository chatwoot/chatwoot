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
    allow(calls_double).to receive(:create).and_return(call_instance)

    allow(Twilio::REST::Client).to receive(:new)
      .with(channel.provider_config_hash['account_sid'], channel.provider_config_hash['auth_token'])
      .and_return(client_double)

    result = adapter.initiate_call(to: '+15550001111', conference_sid: 'CF999', agent_id: 42)
    phone_digits = channel.phone_number.delete_prefix('+')
    expected_url = Rails.application.routes.url_helpers.twilio_voice_call_url(phone: phone_digits)
    expected_status_callback = Rails.application.routes.url_helpers.twilio_voice_status_url(phone: phone_digits)

    expect(calls_double).to have_received(:create).with(hash_including(
                                                          from: channel.phone_number,
                                                          to: '+15550001111',
                                                          url: expected_url,
                                                          status_callback: expected_status_callback,
                                                          status_callback_event: array_including('completed', 'failed', 'busy', 'no-answer',
                                                                                                 'canceled')
                                                        ))
    expect(result[:call_sid]).to eq('CA123')
    expect(result[:conference_sid]).to eq('CF999')
    expect(result[:agent_id]).to eq(42)
    expect(result[:call_direction]).to eq('outbound')
  end
end
