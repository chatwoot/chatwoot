require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::AuditLogs', type: :request do
  describe 'GET /show' do
    it 'returns http success' do
      get '/api/v1/accounts/audit_logs/show'
      expect(response).to have_http_status(:success)
    end
  end
end
