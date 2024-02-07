require 'rails_helper'

RSpec.describe Sla::TriggerSlasForAccountsJob do
  context 'when perform is called' do
    let(:account) { create(:account) }

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('scheduled_jobs')
    end

    it 'calls the ProcessAccountAppliedSlasJob' do
      expect(Sla::ProcessAccountAppliedSlasJob).to receive(:perform_later).with(account).and_call_original
      described_class.perform_now
    end
  end
end
