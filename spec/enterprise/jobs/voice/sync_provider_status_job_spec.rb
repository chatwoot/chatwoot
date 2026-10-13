# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::SyncProviderStatusJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551230000') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(:call, conversation: conversation, provider: :twilio, direction: :outgoing, status: 'ringing', provider_call_id: 'CA-out')
  end
  let(:twilio_call) do
    instance_double(Twilio::REST::Api::V2010::AccountContext::CallInstance, status: 'ringing', start_time: nil, end_time: nil, duration: nil)
  end

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

  it 'keeps the times Twilio has for a call that already ended' do
    started = 2.minutes.ago.change(usec: 0)
    allow(twilio_call).to receive_messages(status: 'completed', start_time: started, end_time: started + 42, duration: '42')

    described_class.perform_now(call.id)

    call.reload
    expect(call.status).to eq('completed')
    expect(call.duration_seconds).to eq(42)
    expect(call.started_at).to eq(started)
  end

  it 'leaves the status of an ended call alone' do
    call.update!(status: 'completed', started_at: 1.minute.ago)

    described_class.perform_now(call.id)

    expect(call.reload.provider_status).to be_nil
  end

  it 'fills in when a call that completed while it asked Twilio was answered' do
    started = 2.minutes.ago.change(usec: 0)
    allow(twilio_call).to receive_messages(status: 'completed', start_time: started, end_time: started + 42, duration: '42')
    calls = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
    allow(calls).to receive(:fetch) do
      # The completed callback lands during the request
      Call.where(id: call.id).update_all(status: 'completed', duration_seconds: 42) # rubocop:disable Rails/SkipsModelValidations
      twilio_call
    end
    allow(call.inbox.channel.client).to receive(:calls).with('CA-out').and_return(calls)

    described_class.perform_now(call.id)

    expect(call.reload).to have_attributes(status: 'completed', started_at: started)
  end

  it 'fills in the start time from a live answer that completion overtook during the request' do
    started = 2.minutes.ago.change(usec: 0)
    allow(twilio_call).to receive_messages(status: 'in-progress', start_time: started)
    calls = instance_double(Twilio::REST::Api::V2010::AccountContext::CallContext)
    allow(calls).to receive(:fetch) do
      Call.where(id: call.id).update_all(status: 'completed', duration_seconds: 42) # rubocop:disable Rails/SkipsModelValidations
      twilio_call
    end
    allow(call.inbox.channel.client).to receive(:calls).with('CA-out').and_return(calls)

    described_class.perform_now(call.id)

    expect(call.reload).to have_attributes(status: 'completed', started_at: started)
  end

  it 'corrects a call a failed join ended unanswered before it ran, when Twilio says it was answered' do
    started = 2.minutes.ago.change(usec: 0)
    call.update!(status: 'no_answer', meta: call.meta.merge('unanswered_by_failed_join' => true, 'ended_at' => (started + 42).to_i))
    allow(twilio_call).to receive_messages(status: 'completed', start_time: started, end_time: started + 42, duration: '42')

    described_class.perform_now(call.id)

    expect(call.reload).to have_attributes(status: 'failed', started_at: started, duration_seconds: 42, provider_status: 'completed')
  end

  it 'fills in the duration along with the start of a call that completed without either' do
    started = 2.minutes.ago.change(usec: 0)
    call.update!(status: 'completed', started_at: nil, duration_seconds: nil)
    allow(twilio_call).to receive_messages(status: 'completed', start_time: started, end_time: started + 42, duration: '42')

    described_class.perform_now(call.id)

    expect(call.reload).to have_attributes(started_at: started, duration_seconds: 42)
  end

  it 'updates the call message when it fills in the times, so clients showing it get them' do
    message = create(:message, conversation: conversation, account: account, content_type: :voice_call, updated_at: 1.hour.ago)
    call.update!(status: 'completed', started_at: nil, message: message)
    allow(twilio_call).to receive_messages(status: 'completed', start_time: 2.minutes.ago, end_time: 1.minute.ago, duration: '60')

    described_class.perform_now(call.id)

    expect(message.reload.updated_at).to be > 1.minute.ago
  end

  it 'fills in when a call that completed before it ran was answered' do
    started = 2.minutes.ago.change(usec: 0)
    call.update!(status: 'completed')
    allow(twilio_call).to receive_messages(status: 'completed', start_time: started)

    described_class.perform_now(call.id)

    expect(call.reload.started_at).to eq(started)
  end
end
