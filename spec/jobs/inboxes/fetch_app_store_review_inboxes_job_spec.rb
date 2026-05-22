# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inboxes::FetchAppStoreReviewInboxesJob do
  let(:account) { create(:account) }
  let(:suspended_account) { create(:account, status: 'suspended') }
  let(:due_channel) { create(:channel_app_store, account: account, last_synced_at: 2.hours.ago) }
  let(:fresh_channel) { create(:channel_app_store, account: account, last_synced_at: 10.minutes.ago) }
  let(:suspended_channel) { create(:channel_app_store, account: suspended_account, last_synced_at: 2.hours.ago) }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('ENABLE_APP_STORE_REVIEWS_CHANNEL', 'false').and_return('true')
  end

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'enqueues fetch jobs only for due channels on active accounts' do
    due_channel
    fresh_channel
    suspended_channel

    expect(Inboxes::FetchAppStoreReviewsJob).to receive(:perform_later).with(due_channel).once
    expect(Inboxes::FetchAppStoreReviewsJob).not_to receive(:perform_later).with(fresh_channel)
    expect(Inboxes::FetchAppStoreReviewsJob).not_to receive(:perform_later).with(suspended_channel)

    described_class.perform_now
  end

  it 'skips channels when the feature is disabled for the account' do
    allow(GlobalConfigService).to receive(:load).with('ENABLE_APP_STORE_REVIEWS_CHANNEL', 'false').and_return('false')
    due_channel

    expect(Inboxes::FetchAppStoreReviewsJob).not_to receive(:perform_later)

    described_class.perform_now
  end
end
