require 'rails_helper'

describe 'Captain toolset install link', type: :request do
  describe 'GET /captain/toolsets/install' do
    it 'redirects to the dashboard install route with only the source' do
      get '/captain/toolsets/install', params: { source: 'chatwoot/tools/linear', redirect: 'https://example.com' }

      expect(response).to have_http_status(:found)
      expect(response.location).to end_with('/app/captain/toolsets/install?source=chatwoot%2Ftools%2Flinear')
    end
  end
end
