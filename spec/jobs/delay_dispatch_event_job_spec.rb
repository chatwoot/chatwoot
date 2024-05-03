require 'rails_helper'

RSpec.describe DelayDispatchEventJob do
  subject(:job) { described_class.perform_later(event_name: event_name, timestamp: timestamp, message_id: message_id) }

  let(:event_name) { 'test_event' }
  let(:timestamp) { Time.now.to_i }
  let(:message_id) { 10 }
  let(:message) { instance_double(Message) }

  before do
    allow(Message).to receive(:find_by).with(id: message_id).and_return(message)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  it 'enqueues the job on the high queue' do
    expect { job }.to have_enqueued_job(described_class)
      .with(event_name: event_name, timestamp: timestamp, message_id: message_id)
      .on_queue('high')
  end

  it 'when the job is performed and the message exists dispatches the event with the correct parameters' do
    described_class.perform_now(event_name: event_name, timestamp: timestamp, message_id: message_id)
    expected_data = { message: message }
    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(event_name, timestamp, expected_data)
  end

  context 'when the job is performed and the message does not exist' do
    let(:message) { nil }

    it 'does not dispatch the event' do
      described_class.perform_now(event_name: event_name, timestamp: timestamp, message_id: message_id)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end
  end
end
