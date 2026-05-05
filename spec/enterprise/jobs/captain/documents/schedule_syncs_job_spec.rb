require 'rails_helper'

RSpec.describe Captain::Documents::ScheduleSyncsJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'business' }) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    create(:installation_config, name: 'CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS', value: { business: 24, hacker: nil }.to_json)
    account.enable_features!('captain_document_auto_sync')
    clear_enqueued_jobs
  end

  context 'when the account has not enabled auto-sync' do
    before { account.disable_features!('captain_document_auto_sync') }

    it 'leaves available documents alone' do
      create(:captain_document, assistant: assistant, account: account, status: :available)
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when the account plan has no sync cadence' do
    let(:account) { create(:account, custom_attributes: { plan_name: 'hacker' }) }

    it 'leaves available documents alone' do
      create(:captain_document, assistant: assistant, account: account, status: :available)
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when an available document has backfilled sync metadata' do
    it 'leaves it alone when last synced within the plan cadence' do
      create(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :available,
        sync_status: :synced,
        last_synced_at: 1.hour.ago
      )
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end

    it 'queues a sync when last synced before the plan cadence' do
      document = create(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :available,
        sync_status: :synced,
        last_synced_at: 3.days.ago
      )
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)
    end

    it 'marks the due document as syncing before queueing' do
      travel_to Time.zone.local(2026, 4, 27, 10, 0, 0) do
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :available,
          sync_status: :synced,
          last_synced_at: 3.days.ago
        )
        clear_enqueued_jobs

        described_class.new.perform

        expect(document.reload).to have_attributes(
          sync_status: 'syncing',
          last_sync_attempted_at: Time.current
        )
      end
    end

    it 'does not queue the same document again while the reserved sync is fresh' do
      document = create(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :available,
        sync_status: :synced,
        last_synced_at: 2.days.ago
      )
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)

      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when an available document was synced within the plan cadence' do
    it 'leaves it alone' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(sync_status: :synced, last_synced_at: 1.hour.ago, last_sync_attempted_at: 1.hour.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when an available document was last synced before the plan cadence' do
    it 'queues a sync for that document' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(sync_status: :synced, last_synced_at: 2.days.ago, last_sync_attempted_at: 2.days.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)
    end
  end

  context 'when more documents are due than the account cap allows' do
    before do
      stub_const("#{described_class}::PER_ACCOUNT_HOURLY_CAP", 2)
    end

    it 'queues backfilled and oldest-attempted documents first' do
      newest_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      oldest_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      backfilled_document = create(:captain_document, assistant: assistant, account: account, status: :available)

      newest_document.update!(sync_status: :synced, last_synced_at: 2.days.ago, last_sync_attempted_at: 2.days.ago)
      oldest_document.update!(sync_status: :synced, last_synced_at: 3.days.ago, last_sync_attempted_at: 3.days.ago)
      backfilled_document.update!(sync_status: :synced, last_synced_at: 4.days.ago, last_sync_attempted_at: nil)
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(backfilled_document)
        .and have_enqueued_job(Captain::Documents::PerformSyncJob).with(oldest_document)
      expect(Captain::Documents::PerformSyncJob).not_to have_been_enqueued.with(newest_document)
    end
  end

  context 'when an available document failed before the plan cadence' do
    it 'queues a sync for that document' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(sync_status: :failed, last_sync_attempted_at: 2.days.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)
    end
  end

  context 'when a document is stuck in syncing past the scheduler stale timeout' do
    it 'requeues a sync to recover the lock' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(
        sync_status: :syncing,
        last_sync_attempted_at: (described_class::SYNC_STALE_TIMEOUT + 1.minute).ago
      )
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)
    end
  end

  context 'when a document has been queued longer than the worker lock timeout' do
    it 'leaves it alone so queue lag is not treated as a dead worker' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(
        sync_status: :syncing,
        last_sync_attempted_at: (Captain::Documents::PerformSyncJob::LOCK_TIMEOUT + 1.minute).ago
      )
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when a document is currently syncing within the scheduler stale timeout' do
    it 'leaves it alone so the holder can finish' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(sync_status: :syncing, last_sync_attempted_at: 1.minute.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when the only eligible document is a PDF' do
    it 'leaves it alone since PDFs are not syncable' do
      pdf_document = build(:captain_document, assistant: assistant, account: account, status: :available)
      pdf_document.pdf_file.attach(io: StringIO.new('PDF content'), filename: 'test.pdf',
                                   content_type: 'application/pdf')
      pdf_document.save!
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end

  context 'when an in-progress (still crawling) document is past the cadence' do
    it 'leaves it alone since only available documents are eligible' do
      document = create(:captain_document, assistant: assistant, account: account, status: :in_progress)
      document.update!(last_sync_attempted_at: 2.days.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)
    end
  end
end
