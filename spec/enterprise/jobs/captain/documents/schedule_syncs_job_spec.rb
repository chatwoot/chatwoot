require 'rails_helper'

RSpec.describe Captain::Documents::ScheduleSyncsJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'business' }) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    set_installation_config('CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS', { business: 168, enterprise: 24, startups: 720, hacker: nil }.to_json)
    set_installation_config('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_BATCH_LIMIT', 50)
    set_installation_config('CAPTAIN_DOCUMENT_AUTO_SYNC_GLOBAL_BATCH_LIMIT', 1000)
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

  def sync_job_for(document)
    have_enqueued_job(Captain::Documents::PerformSyncJob).with(document)
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

  context 'when a plan name is passed' do
    it 'queues due documents only for that plan' do
      enterprise_account = create(:account, custom_attributes: { plan_name: 'Enterprise' })
      enterprise_account.enable_features!('captain_document_auto_sync')
      enterprise_assistant = create(:captain_assistant, account: enterprise_account)
      business_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      enterprise_document = create(:captain_document, assistant: enterprise_assistant, account: enterprise_account, status: :available)

      business_document.update!(sync_status: :synced, last_synced_at: 3.days.ago, last_sync_attempted_at: 3.days.ago)
      enterprise_document.update!(sync_status: :synced, last_synced_at: 3.days.ago, last_sync_attempted_at: 3.days.ago)
      clear_enqueued_jobs

      described_class.new.perform('enterprise')

      expect(Captain::Documents::PerformSyncJob).to have_been_enqueued.with(enterprise_document)
      expect(Captain::Documents::PerformSyncJob).not_to have_been_enqueued.with(business_document)
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
        last_synced_at: 8.days.ago
      )
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to sync_job_for(document).on_queue('purgable')
    end

    it 'delays only the queued sync job' do
      travel_to Time.zone.local(2026, 4, 27, 10, 0, 0) do
        job = described_class.new
        allow(job).to receive(:rand).and_return(30.minutes.to_i)
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :available,
          sync_status: :synced,
          last_synced_at: 8.days.ago
        )
        clear_enqueued_jobs

        job.perform

        expect(Captain::Documents::PerformSyncJob)
          .to have_been_enqueued.with(document).at(30.minutes.from_now)
      end
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
      document.update!(sync_status: :synced, last_synced_at: 8.days.ago, last_sync_attempted_at: 8.days.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to sync_job_for(document)
    end
  end

  context 'when jitter spreads queued sync execution' do
    it 'uses a widened due window so jittered syncs do not skip the next plan run' do
      travel_to Time.zone.local(2026, 4, 27, 10, 0, 0) do
        job = described_class.new
        interval = 1.week
        due_window = (interval.to_i / 2).seconds
        allow(job).to receive(:rand).and_return(2.hours.to_i)
        document = create(:captain_document, assistant: assistant, account: account, status: :available)

        document.update!(sync_status: :synced, last_synced_at: (due_window - 1.minute).ago)
        clear_enqueued_jobs

        expect { job.perform }.not_to have_enqueued_job(Captain::Documents::PerformSyncJob)

        document.update!(sync_status: :synced, last_synced_at: (due_window + 1.minute).ago)
        clear_enqueued_jobs

        expect { job.perform }
          .to have_enqueued_job(Captain::Documents::PerformSyncJob)
          .with(document)
          .on_queue('purgable')
          .at(2.hours.from_now)
      end
    end

    it 'uses a random delay inside the cadence window' do
      travel_to Time.zone.local(2026, 4, 27, 10, 0, 0) do
        document = create(:captain_document, assistant: assistant, account: account, status: :available)
        document.update!(sync_status: :synced, last_synced_at: 8.days.ago)
        job = described_class.new
        sync_execution_delay = 12_345.seconds

        clear_enqueued_jobs
        allow(job).to receive(:rand).with(0..described_class::WEEKLY_SYNC_JITTER.to_i).and_return(sync_execution_delay.to_i)

        expect { job.perform }
          .to sync_job_for(document)
          .at(sync_execution_delay.from_now)
      end
    end
  end

  context 'when more documents are due than the account cap allows' do
    before do
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_BATCH_LIMIT', 2)
    end

    it 'queues backfilled and oldest-attempted documents first' do
      newest_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      oldest_document = create(:captain_document, assistant: assistant, account: account, status: :available)
      backfilled_document = create(:captain_document, assistant: assistant, account: account, status: :available)

      newest_document.update!(sync_status: :synced, last_synced_at: 8.days.ago, last_sync_attempted_at: 8.days.ago)
      oldest_document.update!(sync_status: :synced, last_synced_at: 9.days.ago, last_sync_attempted_at: 9.days.ago)
      backfilled_document.update!(sync_status: :synced, last_synced_at: 10.days.ago, last_sync_attempted_at: nil)
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to sync_job_for(backfilled_document)
        .and sync_job_for(oldest_document)
      expect(Captain::Documents::PerformSyncJob).not_to have_been_enqueued.with(newest_document)
    end
  end

  context 'when sync caps are configured' do
    it 'uses installation config caps for per-account and global limits' do
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_BATCH_LIMIT', 2)
      update_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_GLOBAL_BATCH_LIMIT', 3)

      second_account = create(:account, custom_attributes: { plan_name: 'business' })
      second_account.enable_features!('captain_document_auto_sync')
      second_assistant = create(:captain_assistant, account: second_account)

      first_account_documents = create_list(:captain_document, 3, assistant: assistant, account: account, status: :available)
      second_account_documents = create_list(:captain_document, 3, assistant: second_assistant, account: second_account, status: :available)
      (first_account_documents + second_account_documents).each do |document|
        document.update!(sync_status: :synced, last_synced_at: 8.days.ago, last_sync_attempted_at: 8.days.ago)
      end
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to have_enqueued_job(Captain::Documents::PerformSyncJob).exactly(3).times
    end
  end

  context 'when an available document failed before the plan cadence' do
    it 'queues a sync for that document' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      document.update!(sync_status: :failed, last_sync_attempted_at: 8.days.ago)
      clear_enqueued_jobs

      expect { described_class.new.perform }
        .to sync_job_for(document)
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
        .to sync_job_for(document)
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
