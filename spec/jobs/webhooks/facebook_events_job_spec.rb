require 'rails_helper'

RSpec.describe Webhooks::FacebookEventsJob do
  subject(:job) { described_class.perform_later(params) }

  let(:params) { { test: 'test' } }
  let(:parsed_response) { instance_double(Integrations::Facebook::MessageParser) }
  let(:lock_key) { 'FB_MESSAGE_CREATE_LOCK::sender_id::recipient_id' } # Use a real format if needed
  let(:lock_manager) { instance_double(Redis::LockManager) }

  before do
    allow(Integrations::Facebook::MessageParser).to receive(:new).and_return(parsed_response)
    allow(parsed_response).to receive(:sender_id).and_return('sender_id')
    allow(parsed_response).to receive(:recipient_id).and_return('recipient_id')
    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('default')
  end

  describe 'job execution' do
    context 'when the lock is already acquired' do
      before do
        allow(lock_manager).to receive(:locked?).and_return(true)
      end

      it 'raises a LockAcquisitionError' do
        perform_enqueued_jobs do
          expect { described_class.perform_now(params) }.to raise_error(Webhooks::FacebookEventsJob::LockAcquisitionError)
        end
      end
    end

    context 'when the lock is not acquired' do
      let(:message_creator) { instance_double(Integrations::Facebook::MessageCreator) }

      before do
        allow(lock_manager).to receive(:locked?).and_return(false)
        allow(lock_manager).to receive(:unlock)
        allow(lock_manager).to receive(:lock)
        allow(Integrations::Facebook::MessageCreator).to receive(:new).with(parsed_response).and_return(message_creator)
        allow(message_creator).to receive(:perform)
      end

      it 'invokes the message parser and creator' do
        expect(Integrations::Facebook::MessageParser).to receive(:new).with(params)
        expect(Integrations::Facebook::MessageCreator).to receive(:new).with(parsed_response)
        expect(message_creator).to receive(:perform)

        described_class.perform_now(params)
      end

      it 'acquires and releases the lock' do
        expect(lock_manager).to receive(:lock).with(lock_key)
        expect(lock_manager).to receive(:unlock).with(lock_key)

        described_class.perform_now(params)
      end
    end
  end
end
