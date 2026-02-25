require 'rails_helper'

RSpec.describe 'Webhooks::TelegramController', type: :request do
  describe 'POST /webhooks/telegram/{:bot_token}' do
    it 'call the telegram events job with the params' do
      allow(Webhooks::TelegramEventsJob).to receive(:perform_later)
      expect(Webhooks::TelegramEventsJob).to receive(:perform_later)
      post '/webhooks/telegram/random_bot_token', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end
  end
end
