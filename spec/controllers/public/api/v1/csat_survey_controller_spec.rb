require 'rails_helper'

RSpec.describe 'Public Survey Responses API', type: :request do
  describe 'GET public/api/v1/csat_survey/{uuid}' do
    it 'return the csat response for that conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'input_csat')
      get "/public/api/v1/csat_survey/#{conversation.uuid}"
      data = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(data['conversation_id']).to eq conversation.id
    end

    it 'returns not found error for the open conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'text')
      get "/public/api/v1/csat_survey/#{conversation.uuid}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT public/api/v1/csat_survey/{uuid}' do
    params = { message: { submitted_values: { csat_survey_response: { rating: 4, feedback_message: 'amazing experience' } } } }
    it 'update csat survey response for the conversation' do
      conversation = create(:conversation)
      message = create(:message, conversation: conversation, content_type: 'input_csat')
      # since csat survey is created in async job, we are mocking the creation.
      create(:csat_survey_response, conversation: conversation, message: message, rating: 4, feedback_message: 'amazing experience')
      patch "/public/api/v1/csat_survey/#{conversation.uuid}",
            params: params,
            as: :json
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['conversation_id']).to eq conversation.id
      expect(data['csat_survey_response']['conversation_id']).to eq conversation.id
      expect(data['csat_survey_response']['feedback_message']).to eq 'amazing experience'
      expect(data['csat_survey_response']['rating']).to eq 4
    end

    it 'returns update error if CSAT message sent more than 14 days' do
      conversation = create(:conversation)
      message = create(:message, conversation: conversation, content_type: 'input_csat', created_at: 15.days.ago)
      create(:csat_survey_response, conversation: conversation, message: message, rating: 4, feedback_message: 'amazing experience')
      patch "/public/api/v1/csat_survey/#{conversation.uuid}",
            params: params,
            as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
