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

  context 'when Body parameter is not present' do
    let(:params_without_body) do
      {
        'From' => '+1234567890',
        'To' => '+0987654321',
        'AccountSid' => 'AC123',
        'SmsSid' => 'SM123'
      }
    end

    it 'does not process the event' do
      expect(Twilio::IncomingMessageService).not_to receive(:new)
      described_class.new.perform(params_without_body)
    end
  end
end
