require 'rails_helper'

RSpec.describe DataImports::Freshdesk::ImportJob do
  let(:account) { create(:account) }
  let(:data_import) { create(:data_import, :freshdesk, account: account) }
  let(:importer) { instance_double(DataImports::Freshdesk::Importer) }
  let(:run_id) { 'freshdesk-run-1' }

  before do
    account.enable_features!('data_import')
    data_import.update!(source_metadata: data_import.source_metadata.merge(DataImport::ACTIVE_IMPORT_RUN_ID_KEY => run_id))
    allow(DataImports::Freshdesk::Importer).to receive(:new).with(data_import: data_import, run_id: run_id).and_return(importer)
  end

  describe DataImports::Freshdesk::BaseJob do
    it 'checks rate limit retry before the generic client retry' do
      handlers = described_class.rescue_handlers.map(&:first)

      expect(handlers.index('DataImports::Freshdesk::Client::RateLimitError')).to be > handlers.index('DataImports::Freshdesk::Client::Error')
    end

    it 'schedules a rate-limit retry using the Freshdesk Retry-After header' do
      error = DataImports::Freshdesk::Client::RateLimitError.new('Rate limited', retry_after: '42')
      allow(importer).to receive(:start!).and_raise(error)

      travel_to(Time.zone.parse('2026-07-30 12:00:00 UTC')) do
        expect do
          DataImports::Freshdesk::ImportJob.perform_now(data_import, run_id)
        end.to have_enqueued_job(DataImports::Freshdesk::ImportJob).at(42.seconds.from_now)
      end
    end

    it 'discards a terminal ticket-limit error after recording the failed import' do
      error = CustomExceptions::DataImport::FreshdeskTicketLimitError.new
      allow(importer).to receive_messages(conversations_completed?: false, fail!: true)
      allow(importer).to receive(:import_conversations_page).with(starting_after: nil).and_raise(error)

      expect do
        DataImports::Freshdesk::ConversationsPageJob.perform_now(data_import, nil, run_id)
      end.not_to have_enqueued_job

      expect(importer).to have_received(:fail!).with(error)
    end
  end

  describe DataImports::Freshdesk::ImportJob do
    it 'starts the import and enqueues the first contacts page' do
      allow(importer).to receive_messages(start!: true, import_contacts?: true, contacts_completed?: false, cursor_for: 2)

      expect do
        described_class.perform_now(data_import, run_id)
      end.to have_enqueued_job(DataImports::Freshdesk::ContactsPageJob).with(data_import, 2, run_id).on_queue('low')

      expect(importer).to have_received(:start!)
    end

    it 'skips stale import jobs from an earlier run' do
      data_import.update!(source_metadata: data_import.source_metadata.merge(DataImport::ACTIVE_IMPORT_RUN_ID_KEY => 'new-run'))

      expect(DataImports::Freshdesk::Importer).not_to receive(:new)

      described_class.perform_now(data_import, 'old-run')
    end
  end

  describe DataImports::Freshdesk::ContactsPageJob do
    it 'hands off to tickets after the final contacts page' do
      result = DataImports::Freshdesk::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(
        contacts_completed?: false,
        import_conversations?: true,
        conversations_completed?: false
      )
      allow(importer).to receive(:import_contacts_page).with(starting_after: nil).and_return(result)
      allow(importer).to receive(:cursor_for).with('conversations').and_return(1)

      expect do
        described_class.perform_now(data_import, nil, run_id)
      end.to have_enqueued_job(DataImports::Freshdesk::ConversationsPageJob).with(data_import, 1, run_id)
    end
  end

  describe DataImports::Freshdesk::ConversationsPageJob do
    it 'finishes after the final tickets page' do
      result = DataImports::Freshdesk::Importer::PageResult.new(next_cursor: nil)
      allow(importer).to receive_messages(conversations_completed?: false, finish!: true)
      allow(importer).to receive(:import_conversations_page).with(starting_after: nil).and_return(result)

      expect do
        described_class.perform_now(data_import, nil, run_id)
      end.not_to have_enqueued_job

      expect(importer).to have_received(:finish!)
    end
  end
end
