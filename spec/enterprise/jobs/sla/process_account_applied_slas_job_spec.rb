require 'rails_helper'

RSpec.describe Sla::ProcessAccountAppliedSlasJob do
  context 'when perform is called' do
    let!(:account) { create(:account) }
    let!(:sla_policy) { create(:sla_policy, first_response_time_threshold: 1.hour) }
    let!(:applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'active') }
    let!(:hit_applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'hit') }
    let!(:miss_applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'missed') }

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('medium')
    end

    it 'calls the ProcessAppliedSlaJob' do
      expect(Sla::ProcessAppliedSlaJob).to receive(:perform_later).with(applied_sla).and_call_original
      described_class.perform_now(account)
    end

    it 'does not call the ProcessAppliedSlaJob for not active applied slas' do
      expect(Sla::ProcessAppliedSlaJob).not_to receive(:perform_later).with(hit_applied_sla)
      expect(Sla::ProcessAppliedSlaJob).not_to receive(:perform_later).with(miss_applied_sla)
      described_class.perform_now(account)
    end
  end
end
