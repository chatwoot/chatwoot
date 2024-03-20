require 'rails_helper'

RSpec.describe 'Applied SLAs API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }
  let(:sla_policy) { create(:sla_policy, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/applied_slas/metrics' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/applied_slas/metrics"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the metrics' do
        create(:applied_sla, sla_policy: sla_policy, conversation: conversation)
        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('hit_percentage' => 100.0)
        expect(body).to include('number_of_breaches' => 0)
      end
    end
  end
end
