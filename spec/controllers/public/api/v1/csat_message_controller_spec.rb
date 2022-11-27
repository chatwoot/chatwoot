require 'rails_helper'

RSpec.describe 'Public Csat Message API', type: :request do
  describe 'GET public/api/v1/csat_message/{uuid}' do
    it 'return the csat response for that conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'input_csat')
      get "/public/api/v1/csat_message/#{conversation.uuid}"
      data = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(data['conversation_id']).to eq conversation.id
    end

    it 'returns not found error for the open conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'text')
      get "/public/api/v1/csat_message/#{conversation.uuid}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
