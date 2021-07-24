require 'rails_helper'

describe '/service/response', type: :request do
  describe 'GET service/responses/{uuid}' do
    it 'renders the page correctly when called' do
      conversation = create(:conversation)
      get service_response_url(id: conversation.uuid)
      expect(response).to be_successful
    end

    it 'returns 404 when called with invalid conversation uuid' do
      get service_response_url(id:'')
      expect(response.status).to eq(404)
    end
  end
end
