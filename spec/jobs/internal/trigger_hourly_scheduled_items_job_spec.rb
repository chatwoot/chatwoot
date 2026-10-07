require 'rails_helper'

RSpec.describe Internal::TriggerHourlyScheduledItemsJob do
  subject(:perform_job) { described_class.perform_now }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'triggers Channels::Whatsapp::HealthSyncSchedulerJob' do
    expect(Channels::Whatsapp::HealthSyncSchedulerJob).to receive(:perform_later).once

    perform_job
  end
end
