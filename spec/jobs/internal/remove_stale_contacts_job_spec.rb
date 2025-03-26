require 'rails_helper'

RSpec.describe Internal::RemoveStaleContactsJob do
  subject(:job) { described_class.perform_later }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'calls the RemoveStaleContactsService' do
    service = instance_double(Internal::RemoveStaleContactsService)
    expect(Internal::RemoveStaleContactsService).to receive(:new).and_return(service)
    expect(service).to receive(:perform)
    described_class.perform_now
  end
end
