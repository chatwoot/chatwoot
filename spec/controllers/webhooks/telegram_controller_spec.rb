require 'rails_helper'

RSpec.describe 'Webhooks::TelegramController', type: :request do
  describe 'POST /webhooks/telegram/{:bot_token}' do
    before do
      allow(Webhooks::TelegramEventsJob).to receive(:perform_later)
    end

    it 'calls the telegram events job with the params' do
      expect(Webhooks::TelegramEventsJob).to receive(:perform_later)
      post '/webhooks/telegram/random_bot_token', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end

    it 'acknowledges callback queries in the webhook response' do
      post '/webhooks/telegram/random_bot_token', params: {
        update_id: 123,
        callback_query: { id: 'callback-query-id', data: 'Option 1' }
      }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq(
        'method' => 'answerCallbackQuery',
        'callback_query_id' => 'callback-query-id'
      )
      expect(Webhooks::TelegramEventsJob).to have_received(:perform_later).with(
        hash_including(
          'bot_token' => 'random_bot_token',
          'telegram' => hash_including('callback_query' => hash_including('id' => 'callback-query-id'))
        )
      ).once
    end

    it 'returns an empty response for non-callback updates' do
      post '/webhooks/telegram/random_bot_token', params: { update_id: 123, message: { text: 'hello' } }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).to be_empty
    end

    it 'returns an empty response for a malformed callback query' do
      post '/webhooks/telegram/random_bot_token', params: { update_id: 123, callback_query: 'invalid' }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).to be_empty
      expect(Webhooks::TelegramEventsJob).to have_received(:perform_later).once
    end
  end
end
