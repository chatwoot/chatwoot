require 'rails_helper'

describe '/app', type: :request do
  describe 'GET /app' do
    it 'renders the dashboard' do
      get '/app'
      expect(response).to have_http_status(:success)
    end
  end
end
