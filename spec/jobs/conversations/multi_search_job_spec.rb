require 'rails_helper'

RSpec.describe Conversations::MultiSearchJob, type: :job do
  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('async_database_migration')
  end

  context 'when called' do
    it 'reopens snoozed conversations whose snooze until has passed' do
      described_class.perform_now

      expect { described_class.perform_now }.to have_enqueued_job(Conversations::AccountBasedSearchJob).thrice
                                                                                                       .on_queue('async_database_migration')
    end
  end
end
