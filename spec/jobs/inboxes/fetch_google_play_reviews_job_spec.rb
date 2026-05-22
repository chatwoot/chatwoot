require 'rails_helper'

RSpec.describe Inboxes::FetchGooglePlayReviewsJob do
  let(:channel) { create(:channel_google_play) }
  let(:review) do
    {
      'reviewId' => 'rev-1',
      'authorName' => 'Tester',
      'comments' => [{ 'userComment' => { 'text' => 'good', 'starRating' => 5, 'lastModified' => { 'seconds' => '1' } } }]
    }
  end

  before do
    allow(channel).to receive(:fetch_reviews).and_return([review])
  end

  it 'invokes ReviewBuilder for each fetched review' do
    builder = instance_double(GooglePlay::ReviewBuilder, perform: true)
    allow(GooglePlay::ReviewBuilder).to receive(:new).with(review: review, channel: channel).and_return(builder)

    described_class.perform_now(channel)

    expect(builder).to have_received(:perform)
  end

  it 'stamps last_synced_at after a successful pass' do
    travel_to Time.zone.parse('2026-05-19 12:00') do
      described_class.perform_now(channel)
      expect(channel.reload.last_synced_at).to be_within(1.second).of(Time.current)
    end
  end

  it 'captures per-review errors without aborting the rest of the run' do
    allow(GooglePlay::ReviewBuilder).to receive(:new).and_raise(StandardError, 'boom')
    expect(ChatwootExceptionTracker).to receive(:new).and_call_original

    expect { described_class.perform_now(channel) }.not_to raise_error
  end
end
