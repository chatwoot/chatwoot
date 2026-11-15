require 'rails_helper'

RSpec.describe DataImports::Importer do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :intercom, account: account) }
  let(:importer) { DataImports::Intercom::Importer.new(data_import: data_import) }
  let(:client) { instance_double(DataImports::Intercom::Client) }
  let(:monitor) { create(:conversation_monitor, account: account, created_at: 1.day.ago) }
  let(:contact_payload) { { 'id' => 'contact_1', 'email' => 'customer@example.com', 'name' => 'Customer' } }
  let(:conversation_created_at) { 2.days.ago.to_i }
  let(:message_created_at) { 2.days.ago.to_i }
  let(:conversation_payload) do
    {
      'id' => 'conversation_1', 'created_at' => conversation_created_at, 'state' => 'closed',
      'contacts' => { 'contacts' => [{ 'id' => 'contact_1' }] },
      'source' => { 'id' => 'source_1', 'type' => 'email', 'body' => '',
                    'author' => { 'type' => 'user', 'id' => 'contact_1' } },
      'conversation_parts' => { 'conversation_parts' => [
        { 'id' => 'public_1', 'part_type' => 'comment', 'body' => 'Refund please', 'created_at' => message_created_at,
          'author' => { 'type' => 'user', 'id' => 'contact_1' } }
      ] }
    }
  end

  before do
    account.enable_features!('data_import', 'reports', 'conversation_monitors')
    monitor.initial_scan.update!(enumerated_at: 1.hour.ago)
    allow(DataImports::Intercom::Client).to receive(:new).and_return(client)
    allow(client).to receive(:list_contacts).and_return('data' => [contact_payload], 'pages' => { 'next' => nil })
    allow(client).to receive(:list_conversations).and_return('conversations' => [{ 'id' => 'conversation_1' }], 'pages' => { 'next' => nil })
    allow(client).to receive(:retrieve_conversation).with('conversation_1').and_return(conversation_payload)
    allow(client).to receive(:retrieve_contact).with('contact_1').and_return(contact_payload)
  end

  %w[bulk fallback].product(%w[reports conversation_monitors]).each do |path, feature|
    it "recovers historical #{path} imports after #{feature} is reenabled" do
      account.disable_features!(feature)
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid) if path == 'fallback'
      create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
      endpoint = ConversationMonitors::Configuration.endpoint
      response = { model: monitor.model, answers: { monitor.id.to_s => { type: 'noul', noul: 0.95 } }, usage: { input_tokens: 100 } }
      stub_request(:post, endpoint).to_return(status: 200, body: response.to_json)

      importer.perform

      conversation = account.conversations.sole
      work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
      expect(monitor.evaluations.sole).to have_attributes(status: 'pending', requested_version: monitor.collection_version)
      expect(work).to have_attributes(due_at: be_present, full_history_revision: be > work.processed_revision)
      work.update!(due_at: Time.current)
      ConversationMonitors::Evaluator.new(work).perform
      expect(WebMock).not_to have_requested(:post, endpoint)
      expect { ConversationMonitors::DispatchJob.perform_now }.not_to have_enqueued_job(ConversationMonitors::ProcessJob)

      account.enable_features!(feature)
      expect { ConversationMonitors::DispatchJob.perform_now }.to have_enqueued_job(ConversationMonitors::ProcessJob).with(conversation.id)
      ConversationMonitors::Evaluator.new(work.reload).perform

      expect(monitor.evaluations.sole.status).to eq('matched')
      expect(WebMock).to have_requested(:post, endpoint).once
    end
  end

  %w[bulk fallback].each do |path|
    it "enrolls historical conversations after the initial scan using the #{path} import path" do
      allow(importer).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid) if path == 'fallback'

      importer.perform

      conversation = account.conversations.sole
      work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
      expect(data_import.reload).to be_completed
      expect(monitor.evaluations.sole).to have_attributes(conversation_id: conversation.id, requested_version: monitor.collection_version)
      expect(work).to have_attributes(due_at: be_present, full_history_revision: be > work.processed_revision)
    end

    it "does not schedule unchanged public messages when the #{path} import adds only private notes" do
      importer.perform
      conversation = account.conversations.sole
      work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
      conversation_payload['conversation_parts']['conversation_parts'] << {
        'id' => 'private_1', 'part_type' => 'note', 'body' => 'Private refund discussion',
        'created_at' => 1.hour.ago.to_i, 'author' => { 'type' => 'admin' }
      }
      next_import = DataImports::Intercom::Importer.new(data_import: create(:data_import, :intercom, account: account))
      allow(next_import).to receive(:bulk_write_message_entries).and_raise(ActiveRecord::StatementInvalid) if path == 'fallback'

      expect { next_import.perform }.not_to(change { work.reload.revision })
      expect(conversation.messages.where(private: true).count).to eq(1)
    end
  end

  it 'does not schedule repeated imports without new messages' do
    importer.perform
    work = ConversationMonitors::WorkItem.find_by!(conversation: account.conversations.sole)
    next_import = DataImports::Intercom::Importer.new(data_import: create(:data_import, :intercom, account: account))

    expect { next_import.perform }.not_to(change { work.reload.revision })
  end

  context 'when the conversation predates the initial history window' do
    let(:conversation_created_at) { 10.days.ago.to_i }

    it 'does not enroll historical messages outside the monitor cohort' do
      importer.perform

      expect(monitor.evaluations).not_to exist
      expect(ConversationMonitors::WorkItem.where(account: account)).not_to exist
    end

    context 'with a new public reply during active collection' do
      let(:message_created_at) { 1.hour.ago.to_i }

      it 'enrolls the conversation because of the new reply' do
        importer.perform

        expect(monitor.evaluations.sole.conversation_id).to eq(account.conversations.sole.id)
      end
    end
  end

  %w[catch_up from_now].each do |mode|
    context "when the monitor resumed with #{mode}" do
      let(:message_created_at) { 1.hour.ago.to_i }

      it 'respects the paused-period choice for imported messages' do
        monitor.update!(paused_at: 2.hours.ago)
        ConversationMonitors::Resume.new(monitor, mode: mode, collection_version: monitor.collection_version).perform

        importer.perform

        expect(monitor.evaluations.count).to eq(mode == 'catch_up' ? 1 : 0)
      end
    end
  end
end
