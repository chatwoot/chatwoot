require 'rails_helper'

RSpec.describe Internal::ProcessStaleContactsJob do
  subject(:job) { described_class.perform_later }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'enqueues RemoveStaleContactsJob for each account' do
    account1 = create(:account)
    account2 = create(:account)
    account3 = create(:account)

    expect { described_class.perform_now }.to have_enqueued_job(Internal::RemoveStaleContactsJob)
      .with(account1)
      .on_queue('low')
    expect { described_class.perform_now }.to have_enqueued_job(Internal::RemoveStaleContactsJob)
      .with(account2)
      .on_queue('low')
    expect { described_class.perform_now }.to have_enqueued_job(Internal::RemoveStaleContactsJob)
      .with(account3)
      .on_queue('low')
  end

  it 'processes accounts in batches' do
    account = create(:account)
    allow(Account).to receive(:find_in_batches).with(batch_size: 100).and_yield([account])

    expect(Internal::RemoveStaleContactsJob).to receive(:perform_later).with(account)
    described_class.perform_now
  end
end
