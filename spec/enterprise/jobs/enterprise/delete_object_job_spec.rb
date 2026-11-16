require 'rails_helper'

RSpec.describe DeleteObjectJob, type: :job do
  include ActiveJob::TestHelper
  subject(:job) { described_class.perform_later(account) }

  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:team) { create(:team, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  context 'when an object is passed to the job with arguments' do
    it 'creates log with associated data if its an inbox' do
      described_class.perform_later(inbox, user, '127.0.0.1')
      perform_enqueued_jobs

      audit_log = Audited::Audit.where(auditable_type: 'Inbox', action: 'destroy', username: user.uid, remote_address: '127.0.0.1').first
      expect(audit_log).to be_present
      expect(audit_log.audited_changes.keys).to include('id', 'name', 'account_id')
      expect { inbox.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'will not create logs for other objects' do
      described_class.perform_later(account, user, '127.0.0.1')
      perform_enqueued_jobs
      expect(Audited::Audit.where(auditable_type: 'Team', action: 'destroy').count).to eq 0
    end
  end

  context 'when the object is an sla policy' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let!(:conversations) { create_list(:conversation, 3, account: account, sla_policy: sla_policy) }

    it 'unlinks conversations in batches, purges applied slas and destroys the policy' do
      stub_const('DeleteObjectJob::BATCH_SIZE', 2)

      described_class.perform_now(sla_policy)

      expect(Conversation.where(id: conversations.map(&:id)).pluck(:sla_policy_id)).to all(be_nil)
      expect(AppliedSla.where(sla_policy_id: sla_policy.id)).to be_empty
      expect { sla_policy.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'keeps applied slas when unlinking conversations fails' do
      allow(sla_policy).to receive(:conversations).and_raise(ActiveRecord::QueryCanceled)

      expect { described_class.perform_now(sla_policy) }.to raise_error(ActiveRecord::QueryCanceled)

      expect(AppliedSla.where(sla_policy_id: sla_policy.id).count).to eq(3)
      expect(sla_policy.reload).to be_present
    end
  end
end
