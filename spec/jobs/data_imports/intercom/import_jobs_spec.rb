require 'rails_helper'

RSpec.describe DataImports::Intercom::ImportJob do
  let(:account) { create(:account) }
  let(:data_import) do
    create(
      :data_import, :intercom,
      account: account,
      import_types: %w[contacts conversations]
    )
  end
  let(:importer) { instance_double(DataImports::Intercom::Importer) }
  let(:run_id) { 'intercom-run-1' }

  before do
    account.enable_features!('data_import')
    data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => run_id })
    allow(DataImports::Intercom::Importer).to receive(:new).with(data_import: data_import, run_id: run_id).and_return(importer)
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
    it 'hands off to conversations when a retry finds contacts already completed' do
      allow(importer).to receive_messages(
        contacts_completed?: true,
        import_conversations?: true,
        conversations_completed?: false
      )
      allow(importer).to receive(:cursor_for).with('conversations').and_return('conversation-cursor')
      expect(importer).not_to receive(:import_contacts_page)

      expect do
        described_class.perform_now(data_import, 'completed-contact-cursor', run_id)
      end.to have_enqueued_job(DataImports::Intercom::ConversationsPageJob).with(data_import, 'conversation-cursor', run_id)
    end

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

    it 'skips failed page jobs from backend retries' do
      data_import.update!(status: :failed)

      expect(DataImports::Intercom::Importer).not_to receive(:new)

      described_class.perform_now(data_import, 'current-contact-cursor', run_id)
    end

    it 'does not enqueue another stage when the page import becomes stale' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(contacts_completed?: false, finish!: true)
      allow(importer).to receive(:import_contacts_page).with(starting_after: 'current-contact-cursor') do
        data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
        result
      end

      expect do
        described_class.perform_now(data_import, 'current-contact-cursor', run_id)
      end.not_to have_enqueued_job

      expect(importer).not_to have_received(:finish!)
    end
  end

  describe DataImports::Intercom::ConversationsPageJob do
    it 'finishes when a retry finds conversations already completed' do
      allow(importer).to receive_messages(conversations_completed?: true, finish!: true)
      expect(importer).not_to receive(:import_conversations_page)

      described_class.perform_now(data_import, 'completed-conversation-cursor', run_id)

      expect(importer).to have_received(:finish!)
    end

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

    it 'does not finish when the page import becomes stale' do
      result = DataImports::Intercom::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(conversations_completed?: false, finish!: true)
      allow(importer).to receive(:import_conversations_page).with(starting_after: 'current-conversation-cursor') do
        data_import.update!(source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'new-run' })
        result
      end

      expect do
        described_class.perform_now(data_import, 'current-conversation-cursor', run_id)
      end.not_to have_enqueued_job

      expect(importer).not_to have_received(:finish!)
    end
  end
end
