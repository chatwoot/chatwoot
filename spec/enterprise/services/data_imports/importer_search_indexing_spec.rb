require 'rails_helper'

RSpec.describe DataImports::Importer do
  self.use_transactional_tests = false
  include_context 'with conversation search queue'

  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :intercom, account: account) }
  let(:importer) { DataImports::Intercom::Importer.new(data_import: data_import) }
  let(:client) { instance_double(DataImports::Intercom::Client) }
  let(:contact_payload) { { 'id' => 'contact_1', 'email' => 'imported@example.com', 'name' => 'Imported' } }
  let(:timestamp) { 2.days.ago.to_i }
  let(:conversation_payload) do
    {
      'id' => 'conversation_1', 'created_at' => timestamp, 'state' => 'closed',
      'contacts' => { 'contacts' => [{ 'id' => 'contact_1' }] },
      'source' => { 'id' => 'source_1', 'type' => 'email', 'body' => '', 'author' => { 'type' => 'user', 'id' => 'contact_1' } },
      'conversation_parts' => { 'conversation_parts' => [
        { 'id' => 'message_1', 'part_type' => 'comment', 'body' => 'Hello', 'created_at' => timestamp,
          'author' => { 'type' => 'user', 'id' => 'contact_1' } }
      ] }
    }
  end

  before do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    account.enable_features!('data_import', 'advanced_search_conversations')
    allow(DataImports::Intercom::Client).to receive(:new).and_return(client)
    allow(client).to receive(:list_contacts).and_return('data' => [contact_payload], 'pages' => { 'next' => nil })
    allow(client).to receive(:list_conversations).and_return('conversations' => [{ 'id' => 'conversation_1' }], 'pages' => { 'next' => nil })
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(conversation_payload)
    allow(client).to receive(:retrieve_contact).with('contact_1').and_return(contact_payload)
  end

  after do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
    perform_enqueued_jobs(only: ActiveRecord::DestroyAssociationAsyncJob) do
      account.conversations.destroy_all
      account.contacts.destroy_all
      account.inboxes.destroy_all
      account.destroy!
    end
    Audited::Audit.where(associated: account).or(Audited::Audit.where(auditable: account)).delete_all
  end

  %w[bulk fallback].each do |path|
    it "queues the final conversation state after a #{path} import" do
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid) if path == 'fallback'

      importer.perform

      conversation = account.conversations.sole
      expect(data_import.reload).to be_completed
      expect(reindex_queue.reserve).to include(conversation.id.to_s)
      expect(conversation.last_activity_at.to_i).to eq(timestamp)
    end
  end
end
