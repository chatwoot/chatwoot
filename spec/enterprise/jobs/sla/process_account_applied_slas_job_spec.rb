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
      expect { described_class.perform_later(account) }.to have_enqueued_job(described_class)
        .on_queue('medium')
        .with(account)
    end

    it 'calls the ProcessAppliedSlaJob for both active and active_with_misses' do
      expect(Sla::ProcessAppliedSlaJob).to receive(:perform_later).with(active_with_misses_applied_sla).and_call_original
      expect(Sla::ProcessAppliedSlaJob).to receive(:perform_later).with(applied_sla).and_call_original
      described_class.perform_now(account)
    end

    it 'does not call the ProcessAppliedSlaJob for applied slas that are hit or miss' do
      expect(Sla::ProcessAppliedSlaJob).not_to receive(:perform_later).with(hit_applied_sla)
      expect(Sla::ProcessAppliedSlaJob).not_to receive(:perform_later).with(miss_applied_sla)
      described_class.perform_now(account)
    end
  end
end
