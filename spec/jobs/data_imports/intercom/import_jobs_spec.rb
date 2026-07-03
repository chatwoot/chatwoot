require 'rails_helper'

RSpec.describe DataImports::Intercom::ImportJob do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :intercom, account: account) }
  let(:data_import) do
    create(
      :data_import,
      account: account,
      data_type: 'intercom',
      source_type: 'integration',
      source_provider: 'intercom',
      import_types: %w[contacts conversations],
      integration_hook: hook,
      import_file: nil
    )
  end
  let(:importer) { instance_double(DataImports::Intercom::Importer) }
  let(:run_id) { 'intercom-run-1' }

  before do
    data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
    allow(DataImports::Intercom::Importer).to receive(:new).with(data_import: data_import).and_return(importer)
  end

  describe DataImports::Intercom::BaseJob do
    it 'checks rate limit retry before the generic client retry' do
      expect(described_class.rescue_handlers.last.first).to eq('DataImports::Intercom::Client::RateLimitError')
    end
  end

  describe DataImports::Intercom::ImportJob do
    it 'starts the import and enqueues the first contacts page' do
      allow(importer).to receive_messages(start!: true, import_contacts?: true, contacts_completed?: false, cursor_for: 'contact-cursor')

      expect do
        described_class.perform_now(data_import, run_id)
      end.to have_enqueued_job(DataImports::Intercom::ContactsPageJob).with(data_import, 'contact-cursor', run_id).on_queue('low')

      expect(importer).to have_received(:start!)
    end

    it 'resumes at conversations when contacts are already completed' do
      allow(importer).to receive_messages(
        start!: true,
        import_contacts?: true,
        contacts_completed?: true,
        import_conversations?: true,
        conversations_completed?: false
      )
      allow(importer).to receive(:cursor_for).with('conversations').and_return('conversation-cursor')

      expect do
        described_class.perform_now(data_import, run_id)
      end.to have_enqueued_job(DataImports::Intercom::ConversationsPageJob).with(data_import, 'conversation-cursor', run_id)
    end

    it 'finishes immediately when every requested stage is already complete' do
      allow(importer).to receive_messages(
        start!: true,
        import_contacts?: true,
        contacts_completed?: true,
        import_conversations?: true,
        conversations_completed?: true,
        finish!: true
      )

      expect do
        described_class.perform_now(data_import, run_id)
      end.not_to have_enqueued_job

      expect(importer).to have_received(:finish!)
    end

    it 'skips stale import jobs from an earlier run' do
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })

      expect(DataImports::Intercom::Importer).not_to receive(:new)

      described_class.perform_now(data_import, 'old-run')
    end
  end

  describe DataImports::Intercom::ContactsPageJob do
    it 'imports one contacts page and enqueues the next contacts page' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: 'next-contact-cursor')
      allow(importer).to receive_messages(contacts_completed?: false)
      allow(importer).to receive(:import_contacts_page).with(starting_after: 'current-contact-cursor').and_return(result)

      expect do
        described_class.perform_now(data_import, 'current-contact-cursor', run_id)
      end.to have_enqueued_job(described_class).with(data_import, 'next-contact-cursor', run_id)
    end

    it 'hands off to conversations after the final contacts page' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(
        contacts_completed?: false,
        import_conversations?: true,
        conversations_completed?: false
      )
      allow(importer).to receive(:import_contacts_page).with(starting_after: nil).and_return(result)
      allow(importer).to receive(:cursor_for).with('conversations').and_return(nil)

      expect do
        described_class.perform_now(data_import, nil, run_id)
      end.to have_enqueued_job(DataImports::Intercom::ConversationsPageJob).with(data_import, nil, run_id)
    end

    it 'finishes after the final contacts page when conversations are not requested' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(contacts_completed?: false, import_conversations?: false, finish!: true)
      allow(importer).to receive(:import_contacts_page).with(starting_after: nil).and_return(result)

      expect do
        described_class.perform_now(data_import, nil, run_id)
      end.not_to have_enqueued_job

      expect(importer).to have_received(:finish!)
    end

    it 'skips stale page jobs from an earlier run' do
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })

      expect(DataImports::Intercom::Importer).not_to receive(:new)

      described_class.perform_now(data_import, 'current-contact-cursor', 'old-run')
    end
  end

  describe DataImports::Intercom::ConversationsPageJob do
    it 'imports one conversations page and enqueues the next conversations page' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: 'next-conversation-cursor')
      allow(importer).to receive_messages(conversations_completed?: false)
      allow(importer).to receive(:import_conversations_page).with(starting_after: 'current-conversation-cursor').and_return(result)

      expect do
        described_class.perform_now(data_import, 'current-conversation-cursor', run_id)
      end.to have_enqueued_job(described_class).with(data_import, 'next-conversation-cursor', run_id)
    end

    it 'finishes after the final conversations page' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(conversations_completed?: false, finish!: true)
      allow(importer).to receive(:import_conversations_page).with(starting_after: nil).and_return(result)

      expect do
        described_class.perform_now(data_import, nil, run_id)
      end.not_to have_enqueued_job

      expect(importer).to have_received(:finish!)
    end

    it 'skips stale page jobs from an earlier run' do
      data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })

      expect(DataImports::Intercom::Importer).not_to receive(:new)

      described_class.perform_now(data_import, 'current-conversation-cursor', 'old-run')
    end
  end
end
