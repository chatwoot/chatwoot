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

  context 'when advanced search is enabled' do
    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      # Define the method stub so RSpec can mock it
      # rubocop:disable Lint/EmptyBlock
      Message.define_singleton_method(:searchkick_index) {} unless Message.respond_to?(:searchkick_index)
      # rubocop:enable Lint/EmptyBlock
    end

    it 'cleans up search index when account is deleted' do
      # rubocop:disable RSpec/VerifiedDoubles
      index_double = double('Searchkick::Index')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(Message).to receive(:searchkick_index).and_return(index_double)
      expect(index_double).to receive(:delete_by_query).with(
        body: {
          query: {
            term: { account_id: account.id }
          }
        }
      )

      described_class.perform_now(account, user, '127.0.0.1')
    end

    it 'handles errors gracefully when search cleanup fails' do
      # rubocop:disable RSpec/VerifiedDoubles
      index_double = double('Searchkick::Index')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(Message).to receive(:searchkick_index).and_return(index_double)
      allow(index_double).to receive(:delete_by_query).and_raise(StandardError.new('OpenSearch error'))
      allow(Rails.logger).to receive(:error)

      expect do
        described_class.perform_now(account, user, '127.0.0.1')
      end.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(/Failed to cleanup search index/)
    end
  end

  context 'when advanced search is not enabled' do
    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    end

    it 'does not attempt to cleanup search index' do
      # The method should not even be called since we return early
      described_class.perform_now(account, user, '127.0.0.1')
      # Just verify the account was deleted successfully
      expect { account.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
