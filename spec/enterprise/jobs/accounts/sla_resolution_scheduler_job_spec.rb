require 'rails_helper'

RSpec.describe Accounts::SlaResolutionSchedulerJob do
  context 'when perform is called' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, created_at: 2.hours.ago) }
    let(:sla_policy) { create(:sla_policy, first_response_time_threshold: 1.hour) }
    let(:applied_sla) { create(:applied_sla, conversation: conversation, sla_policy: sla_policy, sla_status: 'active') }

    it 'enqueues the job' do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
        .on_queue('medium')
    end
  end
end
