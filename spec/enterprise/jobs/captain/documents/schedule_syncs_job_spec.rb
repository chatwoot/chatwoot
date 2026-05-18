require 'rails_helper'

RSpec.describe Captain::Documents::ScheduleSyncsJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'business' }) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    set_installation_config('CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS', { business: 24, hacker: nil }.to_json)
    set_installation_config('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_HOURLY_CAP', 50)
    set_installation_config('CAPTAIN_DOCUMENT_AUTO_SYNC_GLOBAL_HOURLY_CAP', 1000)
    account.enable_features!('captain_document_auto_sync')
    clear_enqueued_jobs
  end

  def set_installation_config(name, value)
    InstallationConfig.find_or_initialize_by(name: name).tap do |config|
      config.value = value
      config.save!
    end
  end

  def update_sync_limit(name, value)
    InstallationConfig.find_by!(name: name).update!(value: value)
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
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).with(document).on_queue('purgable')
    end

    it 'reserves the due document until the scheduled sync time before queueing' do
      travel_to Time.zone.local(2026, 4, 27, 10, 0, 0) do
        job = described_class.new
        allow(job).to receive(:sync_jitter).and_return(30.minutes)
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :available,
          sync_status: :synced,
          last_synced_at: 3.days.ago
        )
        clear_enqueued_jobs

        job.perform

        expect(document.reload).to have_attributes(
          sync_status: 'syncing',
          last_sync_attempted_at: 30.minutes.from_now
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

    it 'skips invalid legacy documents without counting them against the account cap' do
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_HOURLY_CAP', 1)
      create(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :in_progress,
        content: nil,
        external_link: 'https://example.com'
      )
      invalid_document = build(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :available,
        sync_status: :synced,
        last_synced_at: 2.days.ago,
        last_sync_attempted_at: 2.days.ago,
        external_link: 'https://example.com/'
      )
      invalid_document.save!(validate: false)
      valid_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      valid_document.update!(sync_status: :synced, last_synced_at: 2.days.ago, last_sync_attempted_at: 2.days.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }.not_to raise_error
      expect(Captain::Documents::PerformSyncJob).not_to have_been_enqueued.with(invalid_document)
      expect(Captain::Documents::PerformSyncJob).to have_been_enqueued.with(valid_document)
    end

    it 'keeps paging due documents when invalid documents fill the first batch' do
      job = described_class.new
      allow(job).to receive(:due_document_candidate_limit).and_return(1)
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_HOURLY_CAP', 1)
      create(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :in_progress,
        content: nil,
        external_link: 'https://example.com'
      )
      invalid_document = build(
        :captain_document,
        assistant: assistant,
        account: account,
        status: :available,
        sync_status: :synced,
        last_synced_at: 2.days.ago,
        last_sync_attempted_at: 3.days.ago,
        external_link: 'https://example.com/'
      )
      invalid_document.save!(validate: false)
      valid_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      valid_document.update!(sync_status: :synced, last_synced_at: 2.days.ago, last_sync_attempted_at: 2.days.ago)
      clear_enqueued_jobs

      job.perform

      expect(Captain::Documents::PerformSyncJob).to have_been_enqueued.with(valid_document)
    end
  end

  context 'when jitter spreads queued sync execution' do
    before do
      InstallationConfig.find_by(name: 'CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS')
                        .update!(value: { business: 168, hacker: nil }.to_json)
    end

    it 'keeps due detection at the plan cadence and delays only the sync job' do
      travel_to Time.zone.local(2026, 4, 27, 10, 0, 0) do
        job = described_class.new
        interval = 1.week
        allow(job).to receive(:sync_jitter).with(interval).and_return(2.hours)
        document = create(:captain_document, assistant: assistant, account: account, status: :available)

        document.update!(sync_status: :synced, last_synced_at: (interval - 1.minute).ago)
        clear_enqueued_jobs

        expect { job.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        document.update!(sync_status: :synced, last_synced_at: (interval + 1.minute).ago)
        clear_enqueued_jobs

        expect { job.perform }
          .to have_enqueued_job(Captain::Documents::PerformSyncJob)
          .with(document)
          .on_queue('purgable')
          .at(2.hours.from_now)
      end
    end

    it 'generates random jitter inside the cadence window' do
      job = described_class.new
      allow(job).to receive(:rand).with(0..described_class::WEEKLY_SYNC_JITTER.to_i).and_return(12_345)

      expect(job.send(:sync_jitter, 1.week)).to eq(12_345.seconds)
    end
  end

  context 'when more documents are due than the account cap allows' do
    before do
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_HOURLY_CAP', 2)
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

  context 'when sync caps are configured' do
    it 'uses installation config caps for per-account and global limits' do
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_HOURLY_CAP', 2)
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_GLOBAL_HOURLY_CAP', 3)

      second_account = create(:account, custom_attributes: { plan_name: 'business' })
      second_account.enable_features!('captain_document_auto_sync')
      second_assistant = create(:captain_assistant, account: second_account)

      first_account_documents = create_list(:captain_document, 3, assistant: assistant, account: account, status: :available)
      second_account_documents = create_list(:captain_document, 3, assistant: second_assistant, account: second_account, status: :available)
      (first_account_documents + second_account_documents).each do |document|
        document.update!(sync_status: :synced, last_synced_at: 3.days.ago, last_sync_attempted_at: 3.days.ago)
      end
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).exactly(3).times

      expect(first_account_documents.count { |document| document.reload.sync_status == 'syncing' }).to eq(2)
      expect(second_account_documents.count { |document| document.reload.sync_status == 'syncing' }).to eq(1)
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
