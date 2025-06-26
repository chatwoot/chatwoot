require 'rails_helper'

RSpec.describe Sla::ProcessAppliedSlaJob do
  context 'when perform is called' do
    let(:account) { create(:account) }
    let(:applied_sla) { create(:applied_sla, account: account) }

    it 'enqueues the job' do
      expect { described_class.perform_later(applied_sla) }.to have_enqueued_job(described_class)
        .with(applied_sla)
        .on_queue('medium')
    end

    it 'calls the EvaluateAppliedSlaService' do
      expect(Sla::EvaluateAppliedSlaService).to receive(:new).with(applied_sla: applied_sla).and_call_original
      described_class.perform_now(applied_sla)
    end
  end
end
