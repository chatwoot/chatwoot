require 'rails_helper'

RSpec.describe Enterprise::SearchIndexing::Conversation do
  self.use_transactional_tests = false
  include_context 'with conversation search queue'

  let(:account) { create(:account) }

  before do
    allow(ChatwootApp).to receive_messages(advanced_search_allowed?: true, chatwoot_cloud?: false)
    account.enable_features!('advanced_search_conversations')
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
    Audited::Audit.where(associated: account).or(Audited::Audit.where(auditable: account)).delete_all
  end

  it 'queues a committed conversation ID through Searchkick' do
    conversation = nil
    Conversation.transaction do
      conversation = create(:conversation, account: account)
      expect(reindex_queue.length).to eq(0)
    end
    expect(reindex_queue.reserve).to eq([conversation.id.to_s])
  end

  it 'does not enqueue rolled back or disabled writes' do
    Conversation.transaction do
      create(:conversation, account: account)
      raise ActiveRecord::Rollback
    end
    expect(reindex_queue.length).to eq(0)
    account.disable_features!('advanced_search_conversations')
    create(:conversation, account: account)
    expect(reindex_queue.length).to eq(0)
  end

  it 'does not depend on the message indexing flag on Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    conversation = create(:conversation, account: account)
    expect(reindex_queue.reserve).to eq([conversation.id.to_s])
  end

  it 'queues subject and activity updates but ignores unrelated metadata' do
    conversation = create(:conversation, account: account)
    reindex_queue.clear
    conversation.reload.update!(additional_attributes: { unrelated: true })
    expect(reindex_queue.length).to eq(0)
    conversation.update!(additional_attributes: { mail_subject: 'Renewal' })
    expect(reindex_queue.reserve).to eq([conversation.id.to_s])
    create(:message, conversation: conversation, account: account, inbox: conversation.inbox)
    expect(reindex_queue.reserve).to include(conversation.id.to_s)
  end

  it 'queues message activity only after the outer transaction commits' do
    conversation = create(:conversation, account: account)
    reindex_queue.clear
    message = nil
    Message.transaction do
      message = create(:message, conversation: conversation, account: account, created_at: 1.minute.ago)
      expect(reindex_queue.length).to eq(0)
    end

    expect(reindex_queue.reserve).to eq([conversation.id.to_s])
    expect(conversation.reload.last_message_at).to eq(message.reload.created_at)
    expect(conversation.search_data['last_activity_at']).to eq(message.created_at)
  end

  it 'does not enqueue or advance clocks for a rolled-back message' do
    conversation = create(:conversation, account: account)
    activity = conversation.last_activity_at
    reindex_queue.clear
    Message.transaction do
      create(:message, conversation: conversation, account: account)
      raise ActiveRecord::Rollback
    end

    expect(reindex_queue.length).to eq(0)
    expect(conversation.reload.last_message_at).to be_nil
    expect(conversation.last_activity_at).to eq(activity)
  end

  it 'indexes private-note activity without advancing the last public message timestamp' do
    conversation = create(:conversation, account: account)
    public_message = create(:message, conversation: conversation, account: account, created_at: 2.minutes.ago)
    reindex_queue.clear
    note = create(:message, conversation: conversation, account: account, message_type: :outgoing, private: true, created_at: 1.minute.ago)

    expect(reindex_queue.reserve).to eq([conversation.id.to_s])
    expect(conversation.reload.last_message_at).to eq(public_message.reload.created_at)
    expect(conversation.search_data['last_activity_at']).to eq(note.reload.created_at)
  end

  [ConnectionPool::TimeoutError, Redis::CannotConnectError, Redis::CommandError].each do |error_class|
    it "reports #{error_class} without interrupting a committed reply or later callbacks" do
      conversation = create(:conversation, account: account)
      reindex_queue.clear
      message = build(:message, conversation: conversation, account: account, message_type: :outgoing)
      error = error_class.new('conversation search queue unavailable')
      tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
      allow(search_index).to receive(:reindex_queue).and_return(reindex_queue)
      allow(reindex_queue).to receive(:push).and_raise(error)
      allow(ChatwootExceptionTracker).to receive(:new).with(error, account: account).and_return(tracker)
      completed = []
      allow(message).to receive(:set_conversation_activity).and_wrap_original do |original|
        original.call
        ActiveRecord.after_all_transactions_commit { completed << :after_indexing }
      end

      expect do
        Message.transaction do
          message.save!
        end
      end.to have_enqueued_job(SendReplyJob).with(message.id)

      expect(message.reload).to be_persisted
      expect(completed).to eq([:after_indexing])
      # Both the first-reply conversation update and deferred message-activity enqueue failed.
      expect(tracker).to have_received(:capture_exception).twice
    end
  end

  it 'keeps unexpected producer errors visible' do
    conversation = create(:conversation, account: account)
    message = build(:message, conversation: conversation, account: account)
    allow(search_index).to receive(:reindex_queue).and_return(reindex_queue)
    allow(reindex_queue).to receive(:push).and_raise(ArgumentError, 'invalid queue arguments')

    expect { message.save! }.to raise_error(ArgumentError, 'invalid queue arguments')
  end

  it 'keeps deletion cleanup active after disabling writes' do
    conversation = create(:conversation, account: account)
    reindex_queue.clear
    account.disable_features!('advanced_search_conversations')
    conversation.destroy!
    expect(reindex_queue.reserve).to eq([conversation.id.to_s])
  end

  it 'does not reindex conversations when contact details change' do
    conversation = create(:conversation, account: account)
    reindex_queue.clear
    conversation.contact.update!(name: 'Updated')
    expect(reindex_queue.length).to eq(0)
  end

  it 'does not reindex conversations for contact CSV updates' do
    conversation = create(:conversation, account: account)
    reindex_queue.clear
    DataImports::Csv::ContactWriter.new(account, { 'email' => conversation.contact.email, 'name' => 'Imported name' }).perform
    expect(conversation.contact.reload.name).to eq('Imported name')
    expect(reindex_queue.length).to eq(0)
  end

  it 'reindexes the contact ID when contacts are merged' do
    conversation = create(:conversation, account: account)
    original_contact = conversation.contact
    target_contact = create(:contact, account: account)
    reindex_queue.clear
    ContactMergeAction.new(account: account, base_contact: target_contact, mergee_contact: original_contact).perform
    expect(conversation.reload.search_data['contact_id']).to eq(target_contact.id)
    expect(reindex_queue.reserve).to include(conversation.id.to_s)
  end
end
