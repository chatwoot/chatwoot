require 'rails_helper'

RSpec.describe Conversations::PendingResolutionJob do
  subject(:job) { described_class.perform_later(account: account) }

  let!(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account, status: :pending) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account: account)
      .on_queue('low')
  end

  it 'does nothing when there is no pending auto resolve duration' do
    conversation.update(last_activity_at: 13.days.ago)
    described_class.perform_now(account: account)
    expect(conversation.reload.status).to eq('pending')
  end

  it 'resolves pending conversations inactive for longer than the configured duration' do
    account.update(auto_resolve_pending_after: 14_400) # 10 days in minutes
    conversation.update(last_activity_at: 13.days.ago)
    described_class.perform_now(account: account)
    expect(conversation.reload.status).to eq('resolved')
  end

  it 'does not resolve pending conversations with recent activity' do
    account.update(auto_resolve_pending_after: 14_400)
    conversation.update(last_activity_at: 2.days.ago)
    described_class.perform_now(account: account)
    expect(conversation.reload.status).to eq('pending')
  end

  it 'does not touch open conversations' do
    account.update(auto_resolve_pending_after: 14_400)
    open_conversation = create(:conversation, account: account, status: :open, last_activity_at: 13.days.ago)
    described_class.perform_now(account: account)
    expect(open_conversation.reload.status).to eq('open')
  end

  it 'sends the configured message before resolving' do
    account.update(auto_resolve_pending_after: 14_400, auto_resolve_pending_message: 'Closing this pending conversation.')
    conversation.update(last_activity_at: 13.days.ago)

    described_class.perform_now(account: account)

    expect(conversation.reload.status).to eq('resolved')
    expect(conversation.messages.template.last.content).to eq('Closing this pending conversation.')
  end

  it 'does not send a message when none is configured' do
    account.update(auto_resolve_pending_after: 14_400)
    conversation.update(last_activity_at: 13.days.ago)

    expect { described_class.perform_now(account: account) }.not_to(change { conversation.messages.count })
    expect(conversation.reload.status).to eq('resolved')
  end

  it 'skips orphan conversations without a contact' do
    account.update(auto_resolve_pending_after: 14_400)
    orphan_conversation = create(:conversation, account: account, status: :pending, last_activity_at: 13.days.ago)
    orphan_conversation.update_columns(contact_id: nil, contact_inbox_id: nil) # rubocop:disable Rails/SkipsModelValidations
    conversation.update(last_activity_at: 13.days.ago)

    described_class.perform_now(account: account)

    expect(orphan_conversation.reload.status).to eq('pending')
    expect(conversation.reload.status).to eq('resolved')
  end

  it 'resolves only a limited number of conversations in a single execution' do
    stub_const('Limits::BULK_ACTIONS_LIMIT', 2)
    account.update(auto_resolve_pending_after: 14_400)
    create_list(:conversation, 3, account: account, status: :pending, last_activity_at: 13.days.ago)
    described_class.perform_now(account: account)
    expect(account.conversations.resolved.count).to eq(Limits::BULK_ACTIONS_LIMIT)
  end
end
