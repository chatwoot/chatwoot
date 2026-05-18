require 'rails_helper'

RSpec.describe Captain::Documents::PerformSyncJob, type: :job do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account, status: :available) }

  def stub_lock(job)
    allow(job).to receive(:with_lock).and_yield
  end

  def stub_page_fetch(content: 'Updated content')
    fetch_result = Captain::Documents::SinglePageFetcher::Result.new(
      success: true,
      title: 'Updated title',
      content: content
    )
    fetcher = instance_double(Captain::Documents::SinglePageFetcher, fetch: fetch_result)
    allow(Captain::Documents::SinglePageFetcher).to receive(:new).and_return(fetcher)
  end

  def stub_page_fetch_failure
    fetcher = instance_double(Captain::Documents::SinglePageFetcher)
    allow(fetcher).to receive(:fetch).and_raise(StandardError, 'boom')
    allow(Captain::Documents::SinglePageFetcher).to receive(:new).and_return(fetcher)
  end

  it 'starts a scheduled auto-sync when the queued job still matches the document' do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      sync_scheduled_at = 30.minutes.from_now
      document.update!(sync_status: :synced, sync_scheduled_at: sync_scheduled_at)
      job = described_class.new
      stub_lock(job)
      stub_page_fetch

      job.perform(document, sync_scheduled_at.to_i)

      expect(document.reload).to have_attributes(
        sync_status: 'synced',
        last_sync_attempted_at: Time.current,
        last_synced_at: Time.current,
        sync_scheduled_at: nil,
        content: 'Updated content'
      )
    end
  end

  it 'leaves the document alone when the queued auto-sync was replaced' do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      sync_scheduled_at = 30.minutes.from_now
      attempted_at = 1.hour.ago
      document.update!(sync_status: :syncing, last_sync_attempted_at: attempted_at, sync_scheduled_at: nil, content: 'Original content')
      job = described_class.new
      stub_lock(job)
      stub_page_fetch(content: 'Should not be applied')

      job.perform(document, sync_scheduled_at.to_i)

      expect(document.reload).to have_attributes(
        sync_status: 'syncing',
        last_sync_attempted_at: attempted_at,
        sync_scheduled_at: nil,
        content: 'Original content'
      )
    end
  end

  it 'starts manual sync even when an auto-sync is scheduled' do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      document.update!(sync_status: :synced, sync_scheduled_at: 30.minutes.from_now)
      job = described_class.new
      stub_lock(job)
      stub_page_fetch

      job.perform(document)

      expect(document.reload).to have_attributes(
        sync_status: 'synced',
        last_sync_attempted_at: Time.current,
        last_synced_at: Time.current,
        sync_scheduled_at: nil,
        content: 'Updated content'
      )
    end
  end

  it 'keeps scheduled auto-sync available for retry after an unexpected failure' do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      sync_scheduled_at = 30.minutes.from_now
      document.update!(sync_status: :synced, sync_scheduled_at: sync_scheduled_at)
      job = described_class.new
      stub_lock(job)
      stub_page_fetch_failure

      expect { job.perform(document, sync_scheduled_at.to_i) }.to raise_error(StandardError, 'boom')

      expect(document.reload).to have_attributes(
        sync_status: 'failed',
        last_sync_error_code: 'sync_error',
        last_sync_attempted_at: Time.current,
        sync_scheduled_at: sync_scheduled_at
      )
    end
  end

  it 'clears scheduled auto-sync when manual sync fails unexpectedly' do
    travel_to Time.zone.local(2026, 5, 18, 10, 0, 0) do
      document.update!(sync_status: :synced, sync_scheduled_at: 30.minutes.from_now)
      job = described_class.new
      stub_lock(job)
      stub_page_fetch_failure

      expect { job.perform(document) }.to raise_error(StandardError, 'boom')

      expect(document.reload).to have_attributes(
        sync_status: 'failed',
        last_sync_error_code: 'sync_error',
        last_sync_attempted_at: Time.current,
        sync_scheduled_at: nil
      )
    end
  end
end
