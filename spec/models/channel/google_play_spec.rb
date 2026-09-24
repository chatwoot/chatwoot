require 'rails_helper'

RSpec.describe Channel::GooglePlay do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:channel) { create(:channel_google_play, account: account) }

  describe 'validations' do
    it 'requires app_id' do
      record = described_class.new(account: account, provider_config: { 'access_token' => 'x' })
      expect(record).not_to be_valid
      expect(record.errors[:app_id]).to include("can't be blank")
    end

    it 'requires app_id to be unique per account' do
      create(:channel_google_play, account: account, app_id: 'com.dup.app')
      duplicate = build(:channel_google_play, account: account, app_id: 'com.dup.app')
      expect(duplicate).not_to be_valid
    end

    it 'allows the same app_id across different accounts' do
      create(:channel_google_play, account: account, app_id: 'com.shared.app')
      other = build(:channel_google_play, account: create(:account), app_id: 'com.shared.app')
      expect(other).to be_valid
    end
  end

  describe '#name' do
    it 'returns the human-readable channel name' do
      expect(channel.name).to eq 'Google PlayStore'
    end
  end

  describe '#sync_due?' do
    it 'is true when last_synced_at is nil' do
      channel.update!(last_synced_at: nil)
      expect(channel.sync_due?).to be true
    end

    it 'is true when last_synced_at is older than the sync interval' do
      channel.update!(last_synced_at: 2.hours.ago)
      expect(channel.sync_due?).to be true
    end

    it 'is false when last_synced_at is within the sync interval' do
      channel.update!(last_synced_at: 10.minutes.ago)
      expect(channel.sync_due?).to be false
    end
  end

  describe '#fetch_reviews' do
    let(:base_url) { "#{described_class::API_BASE_URL}/applications/#{channel.app_id}/reviews" }

    before do
      allow(channel).to receive(:access_token).and_return('test-token')
    end

    it 'returns the reviews list for a single page' do
      stub_request(:get, base_url)
        .with(query: hash_including('maxResults' => '100'))
        .to_return(status: 200, body: { reviews: [{ 'reviewId' => 'r-1' }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(channel.fetch_reviews).to eq([{ 'reviewId' => 'r-1' }])
    end

    it 'follows tokenPagination.nextPageToken across pages' do
      stub_request(:get, base_url)
        .with(query: hash_including('maxResults' => '100'))
        .to_return(
          { status: 200,
            body: { reviews: [{ 'reviewId' => 'r-1' }], tokenPagination: { nextPageToken: 'PAGE2' } }.to_json,
            headers: { 'Content-Type' => 'application/json' } },
          { status: 200,
            body: { reviews: [{ 'reviewId' => 'r-2' }] }.to_json,
            headers: { 'Content-Type' => 'application/json' } }
        )

      expect(channel.fetch_reviews.map { |r| r['reviewId'] }).to eq(%w[r-1 r-2])
    end

    it 'raises when the API responds with an error' do
      stub_request(:get, base_url)
        .with(query: hash_including('maxResults' => '100'))
        .to_return(status: 403, body: 'forbidden')

      expect { channel.fetch_reviews }.to raise_error(/Google Play reviews fetch failed \(403\)/)
    end
  end

  describe '#reply_to_review' do
    let(:url) { "#{described_class::API_BASE_URL}/applications/#{channel.app_id}/reviews/REV-1:reply" }

    before do
      allow(channel).to receive(:access_token).and_return('test-token')
    end

    it 'returns a source_id composed from the review id and lastEdited.seconds' do
      stub_request(:post, url).to_return(
        status: 200,
        body: { result: { replyText: 'thanks', lastEdited: { seconds: '1779000000', nanos: 0 } } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      expect(channel.reply_to_review('REV-1', 'thanks')).to eq('REV-1::reply::1779000000')
    end

    it 'truncates the reply text to MAX_REPLY_LENGTH' do
      stub_request(:post, url).to_return(status: 200,
                                         body: { result: { lastEdited: { seconds: '1' } } }.to_json,
                                         headers: { 'Content-Type' => 'application/json' })

      channel.reply_to_review('REV-1', 'a' * 500)

      expect(WebMock).to(have_requested(:post, url).with do |req|
        JSON.parse(req.body)['replyText'].length <= described_class::MAX_REPLY_LENGTH
      end)
    end

    it 'raises when the API responds with an error' do
      stub_request(:post, url).to_return(status: 400, body: 'bad request')

      expect { channel.reply_to_review('REV-1', 'x') }
        .to raise_error(/Google Play reply failed \(400\)/)
    end
  end

  describe 'after_create_commit' do
    it 'enqueues an initial review fetch' do
      expect do
        create(:channel_google_play, account: account)
      end.to have_enqueued_job(Inboxes::FetchGooglePlayReviewsJob)
    end
  end
end
