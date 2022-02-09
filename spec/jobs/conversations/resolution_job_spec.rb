require 'rails_helper'

RSpec.describe Conversations::ResolutionJob, type: :job do
  subject(:job) { described_class.perform_later(account) }

  let!(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account)
      .on_queue('medium')
  end

  it 'does nothing when there is no auto resolve duration' do
    described_class.perform_now(account: account)
    expect(conversation.reload.status).to eq('open')
  end

  it 'resolves the issue if time of inactivity is more than the auto resolve duration' do
    account.update(auto_resolve_duration: 10)
    conversation.update(last_activity_at: 13.days.ago)
    described_class.perform_now(account: account)
    expect(conversation.reload.status).to eq('resolved')
  end
end
