require 'rails_helper'

RSpec.describe Accounts::TriggerSlaJob do
  context 'when perform is called' do
    let(:account) { create(:account) }

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('scheduled_jobs')
    end
  end
end
