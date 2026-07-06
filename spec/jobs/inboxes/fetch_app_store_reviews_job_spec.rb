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
    allow(AppStore::ReviewBuilder).to receive(:new).with(review_payload: review_payload, channel: channel).and_return(review_builder)

    described_class.perform_now(channel)

    expect(review_builder).to have_received(:perform)
    expect(channel.reload.last_synced_at).to eq(Time.zone.parse('2026-05-20T10:00:00-00:00'))
  end

  it 'updates the sync timestamp to the latest fetched review date' do
    older_payload = review_payload.deep_dup
    newer_payload = review_payload.deep_dup
    older_payload['review']['id'] = 'review-1'
    older_payload['review']['attributes']['createdDate'] = '2026-05-20T10:00:00-00:00'
    newer_payload['review']['id'] = 'review-2'
    newer_payload['review']['attributes']['createdDate'] = '2026-05-20T11:00:00-00:00'

    allow(channel).to receive(:fetch_reviews).and_return([newer_payload, older_payload])
    allow(AppStore::ReviewBuilder).to receive(:new).and_return(review_builder)

    described_class.perform_now(channel)

    expect(channel.reload.last_synced_at).to eq(Time.zone.parse('2026-05-20T11:00:00-00:00'))
  end

  it 'updates the sync timestamp to the response update date when it is newer than the review date' do
    payload = review_payload.deep_dup
    payload['response'] = {
      'id' => 'response-1',
      'attributes' => {
        'lastModifiedDate' => '2026-05-20T12:00:00-00:00'
      }
    }

    allow(channel).to receive(:fetch_reviews).and_return([payload])
    allow(AppStore::ReviewBuilder).to receive(:new).and_return(review_builder)

    described_class.perform_now(channel)

    expect(channel.reload.last_synced_at).to eq(Time.zone.parse('2026-05-20T12:00:00-00:00'))
  end

  it 'does not move the sync timestamp backwards when processing an older response update' do
    channel.update!(last_synced_at: Time.zone.parse('2026-05-20T13:00:00-00:00'))
    payload = review_payload.deep_dup
    payload['response'] = {
      'id' => 'response-1',
      'attributes' => {
        'lastModifiedDate' => '2026-05-20T12:00:00-00:00'
      }
    }

    allow(channel).to receive(:fetch_reviews).and_return([payload])
    allow(AppStore::ReviewBuilder).to receive(:new).and_return(review_builder)

    described_class.perform_now(channel)

    expect(channel.reload.last_synced_at).to eq(Time.zone.parse('2026-05-20T13:00:00-00:00'))
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
