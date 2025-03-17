require 'rails_helper'

RSpec.describe Webhooks::TwilioEventsJob do
  subject(:job) { described_class.perform_later(params) }

  let(:params) do
    {
      'From' => '+1234567890',
      'To' => '+0987654321',
      'Body' => 'Test message',
      'AccountSid' => 'AC123',
      'SmsSid' => 'SM123'
    }
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('low')
  end

  it 'calls the Twilio::IncomingMessageService' do
    service = double
    expect(Twilio::IncomingMessageService).to receive(:new).with(params: params).and_return(service)
    expect(service).to receive(:perform)
    described_class.new.perform(params)
  end
end
