require 'rails_helper'

RSpec.describe 'Public Survey Responses API', type: :request do
  describe 'GET public/api/v1/csat_survey/{uuid}' do
    it 'return the csat response for that conversation' do
      conversation = create(:conversation)
      create(:message, conversation: conversation, content_type: 'input_csat')
      get "/public/api/v1/csat_survey/#{conversation.uuid}"
      data = response.parsed_body
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
      data = response.parsed_body
      expect(data['conversation_id']).to eq conversation.id
      expect(data['csat_survey_response']['conversation_id']).to eq conversation.id
      expect(data['csat_survey_response']['feedback_message']).to eq 'amazing experience'
      expect(data['csat_survey_response']['rating']).to eq 4
    end

    it 'accepts responses beyond the default window when the inbox allows more time' do
      conversation = create(:conversation)
      conversation.inbox.update!(csat_config: { response_window_days: 30 })
      message = create(:message, conversation: conversation, content_type: 'input_csat', created_at: 20.days.ago)

      patch "/public/api/v1/csat_survey/#{conversation.uuid}", params: params, as: :json

      expect(response).to have_http_status(:success)
      expect(message.reload.submitted_values.dig('csat_survey_response', 'rating')).to eq(4)
    end

    it 'rejects a submission at the configured deadline without saving it' do
      conversation = create(:conversation)
      conversation.inbox.update!(csat_config: { response_window_days: 1 })
      message = create(:message, conversation: conversation, content_type: 'input_csat', created_at: Time.current.change(usec: 0))

      travel_to(message.created_at + 24.hours) do
        patch "/public/api/v1/csat_survey/#{conversation.uuid}", params: params, as: :json
      end

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('You cannot update the CSAT survey after 1 day')
      expect(message.reload.submitted_values).to be_nil
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
