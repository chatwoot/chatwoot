require 'rails_helper'
RSpec.describe Sla::TriggerSlasForAccountsJob do
  context 'when perform is called' do
    let(:account_with_sla) { create(:account) }
    let(:account_without_sla) { create(:account) }

    before do
      create(:sla_policy, account: account_with_sla)
    end

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('scheduled_jobs')
    end

    it 'calls the ProcessAccountAppliedSlasJob for accounts with SLA' do
      expect(Sla::ProcessAccountAppliedSlasJob).to receive(:perform_later).with(account_with_sla).and_call_original
      described_class.perform_now
    end

    it 'does not call the ProcessAccountAppliedSlasJob for accounts without SLA' do
      expect(Sla::ProcessAccountAppliedSlasJob).not_to receive(:perform_later).with(account_without_sla)
      described_class.perform_now
    end
  end
end
