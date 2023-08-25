require 'rails_helper'

RSpec.describe Webhooks::FacebookEventsJob do
  subject(:job) { described_class.perform_later(params) }

  let(:params) { { test: 'test' } }
  let(:parsed_response) { instance_double(Integrations::Facebook::MessageParser) }
  let(:lock_key_format) { Redis::Alfred::FACEBOOK_MESSAGE_MUTEX }
  let(:lock_key) { format(lock_key_format, sender_id: 'sender_id', recipient_id: 'recipient_id') } # Use real format if different

  before do
    allow(Integrations::Facebook::MessageParser).to receive(:new).and_return(parsed_response)
    allow(parsed_response).to receive(:sender_id).and_return('sender_id')
    allow(parsed_response).to receive(:recipient_id).and_return('recipient_id')
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('default')
  end

  describe 'job execution' do
    let(:message_creator) { instance_double(Integrations::Facebook::MessageCreator) }

    before do
      allow(Integrations::Facebook::MessageParser).to receive(:new).and_return(parsed_response)
      allow(Integrations::Facebook::MessageCreator).to receive(:new).with(parsed_response).and_return(message_creator)
      allow(message_creator).to receive(:perform)
    end

    # ensures that the response is built
    it 'invokes the message parser and creator' do
      expect(Integrations::Facebook::MessageParser).to receive(:new).with(params)
      expect(Integrations::Facebook::MessageCreator).to receive(:new).with(parsed_response)
      expect(message_creator).to receive(:perform)

      described_class.perform_now(params)
    end

    # this test ensures that the process message function is indeed called
    it 'attempts to acquire a lock and then processes the message' do
      job_instance = described_class.new
      allow(job_instance).to receive(:process_message).with(parsed_response)

      job_instance.perform(params)

      expect(job_instance).to have_received(:process_message).with(parsed_response)
    end
  end
end
