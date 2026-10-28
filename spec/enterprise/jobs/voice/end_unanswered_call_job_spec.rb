require 'rails_helper'

RSpec.describe Voice::EndUnansweredCallJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation) }
  let(:service) { instance_double(Voice::RingingTimeoutService, perform: nil) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(Voice::RingingTimeoutService).to receive(:new).with(call: call).and_return(service)
  end

  it 'ends the unanswered call' do
    described_class.perform_now(call.id)

    expect(service).to have_received(:perform)
  end

  it 'checks again once an agent connection on its way in has had its time to join' do
    allow(service).to receive(:perform).and_return(12)

    expect { described_class.perform_now(call.id) }
      .to have_enqueued_job(described_class).with(call.id).at(a_value_within(2.seconds).of(12.seconds.from_now))
  end

  it 'retries when Twilio cannot be reached' do
    allow(service).to receive(:perform).and_raise(Twilio::REST::TwilioError)

    expect { described_class.perform_now(call.id) }.to have_enqueued_job(described_class).with(call.id)
  end
end
