require 'rails_helper'

RSpec.describe Migration::RemoveMessageNotifications do
  subject(:job) { described_class.perform_later }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end
end
