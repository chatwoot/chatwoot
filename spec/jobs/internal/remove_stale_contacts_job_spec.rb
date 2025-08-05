require 'rails_helper'

RSpec.describe Internal::RemoveStaleContactsJob do
  subject(:job) { described_class.perform_later(account) }

  let(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account)
      .on_queue('housekeeping')
  end

  it 'calls the RemoveStaleContactsService' do
    service = instance_double(Internal::RemoveStaleContactsService)
    expect(Internal::RemoveStaleContactsService).to receive(:new).with(account: account).and_return(service)
    expect(service).to receive(:perform)
    described_class.perform_now(account)
  end
end
