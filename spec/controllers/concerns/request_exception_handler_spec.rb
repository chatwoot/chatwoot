require 'rails_helper'

RSpec.describe RequestExceptionHandler, type: :request do
  describe 'malformed request body' do
    it 'returns bad_request for invalid JSON body' do
      put '/api/v1/profile',
          params: 'invalid{json',
          headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('Invalid request: malformed body')
    end
  end
end
