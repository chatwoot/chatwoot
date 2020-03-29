require 'rails_helper'

RSpec.describe EventDispatcherJob, type: :job do
  subject(:job) { described_class.perform_later(event_name, timestamp, event_data) }

  let!(:conversation) { create(:conversation) }
  let(:event_name) { 'conversation.created' }
  let(:timestamp) { Time.zone.now }
  let(:event_data) { { conversation: conversation } }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(event_name, timestamp, event_data)
      .on_queue('events')
  end

  it 'publishes event' do
    expect(Rails.configuration.dispatcher.async_dispatcher).to receive(:publish_event).with(event_name, timestamp, event_data).once
    event_dispatcher = described_class.new
    event_dispatcher.perform(event_name, timestamp, event_data)
  end
end
