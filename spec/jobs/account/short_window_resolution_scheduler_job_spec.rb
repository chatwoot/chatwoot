require 'rails_helper'

RSpec.describe Account::ShortWindowResolutionSchedulerJob do
  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'enqueues Conversations::ResolutionJob only for accounts resolving within 10 minutes' do
    short_window_account = create(:account, auto_resolve_after: 5)
    create(:account, auto_resolve_after: 10)
    create(:account)

    expect { described_class.perform_now }.to have_enqueued_job(Conversations::ResolutionJob)
      .with(account: short_window_account).exactly(:once)
  end
end
