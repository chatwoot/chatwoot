require 'rails_helper'

RSpec.describe Inboxes::FetchGooglePlayReviewInboxesJob do
  include ActiveJob::TestHelper

  let!(:due_channel) { create(:channel_google_play, last_synced_at: 2.hours.ago) }
  let!(:fresh_channel) { create(:channel_google_play, last_synced_at: 5.minutes.ago) }
  let!(:never_synced_channel) { create(:channel_google_play, last_synced_at: nil) }

  before { clear_enqueued_jobs } # also clear the after_create_commit fetches from factory

  it 'enqueues a fetch job for channels whose sync interval has elapsed' do
    described_class.perform_now

    expect(Inboxes::FetchGooglePlayReviewsJob).to have_been_enqueued.with(due_channel).once
    expect(Inboxes::FetchGooglePlayReviewsJob).to have_been_enqueued.with(never_synced_channel).once
    expect(Inboxes::FetchGooglePlayReviewsJob).not_to have_been_enqueued.with(fresh_channel)
  end

  it 'skips inboxes belonging to suspended accounts' do
    due_channel.account.update!(status: :suspended)

    described_class.perform_now

    expect(Inboxes::FetchGooglePlayReviewsJob).not_to have_been_enqueued.with(due_channel)
  end
end
