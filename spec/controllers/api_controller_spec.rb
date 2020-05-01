require 'rails_helper'

RSpec.describe 'API Base', type: :request do
  describe 'request to api base url' do
    it 'returns api version' do
      get '/api/'
      expect(response).to have_http_status(:success)
      expect(response.body).to include(Chatwoot.config[:version])
    end
  end
end
