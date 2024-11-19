require 'rails_helper'

describe '/survey/response', type: :request do
  describe 'GET survey/responses/{uuid}' do
    it 'renders the page correctly when called' do
      conversation = create(:conversation)
      get survey_response_url(id: conversation.uuid)
      expect(response).to be_successful
    end

    it 'returns 404 when called with invalid conversation uuid' do
      get survey_response_url(id: '')
      expect(response).to have_http_status(:not_found)
    end
  end
end
