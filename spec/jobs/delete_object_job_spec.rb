require 'rails_helper'

RSpec.describe DeleteObjectJob, type: :job do
  subject(:job) { described_class.perform_later(account) }

  let(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account)
      .on_queue('default')
  end

  context 'when an object is passed to the job' do
    it 'is deleted' do
      described_class.perform_now(account)
      expect { account.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
