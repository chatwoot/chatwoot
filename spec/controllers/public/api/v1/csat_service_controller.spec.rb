require 'rails_helper'

RSpec.describe 'Public Survey Responses API', type: :request do
  describe 'GET public/api/v1/csat_service/{uuid}' do
    it 'return the csat response for that conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'input_csat')
      get "/public/api/v1/csat_service/#{conversation.uuid}"
      data = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(data['conversation_id']).to eq conversation.id
    end

    it 'returns not found error for the open conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'text')
      get "/public/api/v1/csat_service/#{conversation.uuid}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT public/api/v1/csat_service/{uuid}' do
    it 'update csat survey response for the conversation' do
      conversation = create(:conversation)
      message = create(:message, conversation: conversation, content_type: 'input_csat')
      patch "/public/api/v1/csat_service/#{conversation.uuid}",
            params: { message: { submitted_values: { csat_survey_response: { rating: 4, feedback_message: 'amazing' } } } },
            as: :json
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['conversation_id']).to eq conversation.id
    end

    it 'returns update error if CSAT message sent more than 14 days' do
      conversation = create(:conversation)
      message = create(:message, conversation: conversation, content_type: 'input_csat', created_at: Time.now - 15.days)
      patch "/public/api/v1/csat_service/#{conversation.uuid}",
            params: { message: { submitted_values: { csat_survey_response: { rating: 4, feedback_message: 'amazing' } } } },
            as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
