require 'rails_helper'

RSpec.describe 'Webhooks::LineController', type: :request do
  describe 'POST /webhooks/line/:line_channel_id' do
    it 'passes the raw body and signature header into the job' do
      allow(Webhooks::LineEventsJob).to receive(:perform_later)

      post '/webhooks/line/line-channel-id',
           params: '{"events":[]}',
           headers: {
             'CONTENT_TYPE' => 'application/json',
             'X-Line-Signature' => 'sig-123'
           }

      expect(Webhooks::LineEventsJob).to have_received(:perform_later).with(
        params: hash_including('line_channel_id' => 'line-channel-id'),
        signature: 'sig-123',
        post_body: '{"events":[]}'
      )
    end
  end
end
