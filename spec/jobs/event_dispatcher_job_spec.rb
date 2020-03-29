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
end
