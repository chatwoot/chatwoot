# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inboxes::FetchAppStoreReviewsJob do
  let(:channel) { create(:channel_app_store, last_synced_at: nil) }
  let(:review_payload) do
    {
      'review' => {
        'id' => 'review-1',
        'attributes' => { 'createdDate' => '2026-05-20T10:00:00-00:00' }
      },
      'response' => nil
    }
  end
  let(:review_builder) { instance_double(AppStore::ReviewBuilder, perform: true) }

  before do
    channel.account.enable_features!(:channel_app_store)
  end

  it 'enqueues the job' do
    expect { described_class.perform_later(channel) }.to have_enqueued_job(described_class)
      .with(channel)
      .on_queue('scheduled_jobs')
  end

  it 'fetches reviews, builds messages, and updates the sync timestamp' do
    allow(channel).to receive(:fetch_reviews).and_return([review_payload])
    allow(AppStore::ReviewBuilder).to receive(:new).with(hash_including(review_payload: review_payload, channel: channel)).and_return(review_builder)

    described_class.perform_now(channel)

    expect(review_builder).to have_received(:perform)
    expect(channel.reload.last_synced_at).to be_within(1.second).of(Time.current)
  end

  it 'captures per-review errors and continues syncing' do
    exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)

    allow(channel).to receive(:fetch_reviews).and_return([review_payload])
    allow(AppStore::ReviewBuilder).to receive(:new).and_return(review_builder)
    allow(review_builder).to receive(:perform).and_raise(StandardError, 'bad review')
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)

    described_class.perform_now(channel)

    expect(exception_tracker).to have_received(:capture_exception)
  end

  it 'does not update the sync timestamp when a review fails to build' do
    exception_tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)

    channel.update!(last_synced_at: 2.hours.ago)
    allow(channel).to receive(:fetch_reviews).and_return([review_payload])
    allow(AppStore::ReviewBuilder).to receive(:new).and_return(review_builder)
    allow(review_builder).to receive(:perform).and_raise(StandardError, 'bad review')
    allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)

    expect { described_class.perform_now(channel) }
      .not_to change(channel.reload, :last_synced_at)
  end

  it 'does not fetch reviews when the feature is disabled for the account' do
    channel.account.disable_features!(:channel_app_store)

    expect(channel).not_to receive(:fetch_reviews)

    described_class.perform_now(channel)
  end
end
