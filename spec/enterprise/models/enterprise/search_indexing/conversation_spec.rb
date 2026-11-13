require 'rails_helper'

RSpec.describe Enterprise::SearchIndexing::Conversation do
  self.use_transactional_tests = false
  include_context 'with search indexing Redis'

  let(:account) { create(:account) }
  let(:buffer) { SearchIndexing::Buffer.new(entity: 'conversations', account_id: account.id) }
  let(:dependencies) { SearchIndexing::Buffer.new(entity: 'contact_conversations', account_id: account.id) }

  before do
    allow(ChatwootApp).to receive_messages(advanced_search_allowed?: true, chatwoot_cloud?: false)
    account.enable_features!('conversation_search_indexing')
  end

  after do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    users = account.users.to_a
    perform_enqueued_jobs(only: ActiveRecord::DestroyAssociationAsyncJob) do
      account.conversations.destroy_all
      account.contacts.destroy_all
      account.inboxes.destroy_all
      account.destroy! unless account.destroyed?
      users.each(&:destroy!)
    end
  end

  it 'queues a created conversation only after the transaction commits' do
    conversation = nil
    Conversation.transaction do
      conversation = create(:conversation, account: account)
      expect(buffer.statistics[:pending]).to eq(0)
    end
    expect(buffer.claim[:revisions].keys).to eq([conversation.id.to_s])
  end

  it 'does not queue rolled-back conversations' do
    Conversation.transaction do
      create(:conversation, account: account)
      raise ActiveRecord::Rollback
    end
    expect(buffer.statistics[:pending]).to eq(0)
  end

  it 'does not queue conversations when indexing is disabled' do
    account.disable_features!('conversation_search_indexing')
    create(:conversation, account: account)
    expect(buffer.statistics[:pending]).to eq(0)
  end

  it 'requires the Cloud indexing entitlement' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:conversation, account: account)
    expect(buffer.statistics[:pending]).to eq(0)
    account.enable_features!('advanced_search_indexing')
    conversation = create(:conversation, account: account)
    expect(buffer.claim[:revisions].keys).to eq([conversation.id.to_s])
  end

  it 'refreshes conversation metadata after contact identity edits without indexing the contact' do
    conversation = create(:conversation, account: account)
    contact = conversation.contact
    contact.update!(last_activity_at: Time.current)
    expect(dependencies.statistics[:pending]).to eq(0)
    contact.update!(name: 'Changed name')
    expect(dependencies.claim[:revisions].keys).to eq([contact.id.to_s])
    expect { SearchIndexing::Buffer.new(entity: 'contacts', account_id: account.id) }.to raise_error(KeyError)
  end

  it 'queues email subject changes but not unrelated conversation attributes' do
    conversation = create(:conversation, account: account)
    conversation.reload
    batch = buffer.claim
    buffer.acknowledge(batch, [{ id: conversation.id.to_s, revision: batch[:revisions][conversation.id.to_s], state: 'success' }])
    conversation.update!(additional_attributes: { unrelated: true })
    expect(buffer.statistics[:pending]).to eq(0)
    conversation.update!(additional_attributes: { mail_subject: 'Invoice renewal' })
    expect(buffer.claim[:revisions].keys).to eq([conversation.id.to_s])
  end

  it 'keeps deletion cleanup active after disabling indexing' do
    conversation = create(:conversation, account: account)
    conversation.reload
    batch = buffer.claim
    buffer.acknowledge(batch, [{ id: conversation.id.to_s, revision: batch[:revisions][conversation.id.to_s], state: 'success' }])
    account.disable_features!('conversation_search_indexing')
    conversation.destroy!
    expect(buffer.claim[:revisions].keys).to eq([conversation.id.to_s])
  end
end
