require 'rails_helper'

RSpec.describe Conversations::MultiSearchJob, type: :job do
  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class).once.on_queue('async_database_migration')
  end

  context 'when called' do
    let(:account) { create(:account) }

    it 'Calls the account based search job' do
      expect { described_class.perform_now }.to have_enqueued_job(Conversations::AccountBasedSearchJob).once.on_queue('async_database_migration')
    end
  end
end
