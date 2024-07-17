require 'rails_helper'

RSpec.describe Sla::ProcessAppliedSlaJob do
  context 'when perform is called' do
    let(:account) { create(:account) }

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('medium')
    end

    it 'calls the EvaluateAppliedSlaService' do
      applied_sla = create(:applied_sla)
      expect(Sla::EvaluateAppliedSlaService).to receive(:new).with(applied_sla: applied_sla).and_call_original
      described_class.perform_now(applied_sla)
    end
  end
end
