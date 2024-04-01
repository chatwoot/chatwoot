require 'rails_helper'

RSpec.describe Sla::ProcessAccountAppliedSlasJob do
  context 'when perform is called' do
    let!(:account) { create(:account) }
    let!(:sla_policy) { create(:sla_policy, first_response_time_threshold: 1.hour) }
    let!(:applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'active') }
    let!(:hit_applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'hit') }
    let!(:miss_applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'missed') }
    let!(:active_with_misses_applied_sla) { create(:applied_sla, account: account, sla_policy: sla_policy, sla_status: 'active_with_misses') }

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('medium')
    end

    it 'calls the EvaluateAppliedSlaService for both active and active_with_misses' do
      expect(Sla::EvaluateAppliedSlaService).to receive(:perform).with(active_with_misses_applied_sla).and_call_original
      expect(Sla::EvaluateAppliedSlaService).to receive(:perform).with(applied_sla).and_call_original
      described_class.perform_now(account)
    end

    it 'does not call the EvaluateAppliedSlaService for applied slas that are hit or miss' do
      expect(Sla::EvaluateAppliedSlaService).not_to receive(:perform).with(hit_applied_sla)
      expect(Sla::EvaluateAppliedSlaService).not_to receive(:perform).with(miss_applied_sla)
      described_class.perform_now(account)
    end
  end
end
