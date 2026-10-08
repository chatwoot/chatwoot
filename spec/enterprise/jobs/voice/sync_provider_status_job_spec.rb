# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::SyncProviderStatusJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551230000') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(:call, conversation: conversation, provider: :twilio, direction: :outgoing, status: 'ringing', provider_call_id: 'CA-out')
  end
  let(:twilio_call) { instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'ringing') }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    calls = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext, fetch: twilio_call)
    client = instance_double(Twilio::REST::Client)
    allow(client).to receive(:calls).with('CA-out').and_return(calls)
    allow(Call).to receive(:find_by).with(id: call.id).and_return(call)
    allow(call.inbox.channel).to receive(:client).and_return(client)
  end

  it 'records the status Twilio has for the call' do
    described_class.perform_now(call.id)

    expect(call.reload.provider_status).to eq('ringing')
  end

  it 'leaves an ended call alone' do
    call.update!(status: 'completed')

    described_class.perform_now(call.id)

    expect(call.reload.provider_status).to be_nil
  end
end
