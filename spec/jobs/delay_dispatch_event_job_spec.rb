require 'rails_helper'

RSpec.describe DelayDispatchEventJob do
  subject(:job) { described_class.perform_later(event_name: event_name, timestamp: timestamp, message_id: message.id) }

  let(:event_name) { 'message.created' }
  let(:timestamp) { Time.now.to_i }
  let!(:message) { create(:message, message_type: :incoming) }

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  it 'enqueues the job on the high queue' do
    expect { job }.to have_enqueued_job(described_class)
      .with(event_name: event_name, timestamp: timestamp, message_id: message.id)
      .on_queue('high')
  end

  context 'when the job is performed and the message exists' do
    it 'dispatches the event with the correct parameters' do
      described_class.perform_now(event_name: event_name, timestamp: timestamp, message_id: message.id)
      expected_data = { message: message }
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(event_name, timestamp, expected_data)
    end
  end

  context 'when the job is performed and the message does not exist' do
    before { message.destroy }

    it 'does not dispatch the event' do
      described_class.perform_now(event_name: event_name, timestamp: timestamp, message_id: message.id)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
    end
  end
end
