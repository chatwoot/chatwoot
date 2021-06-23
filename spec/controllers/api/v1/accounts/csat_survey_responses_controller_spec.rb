require 'rails_helper'

RSpec.describe 'CSAT Survey Responses API', type: :request do
  let(:account) { create(:account) }
  let!(:csat_survey_response) { create(:csat_survey_response, account: account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }


  describe 'GET /api/v1/accounts/{account.id}/csat_survey_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns all the csat survey responses for administrators' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).first['feedback_text']).to eq(csat_survey_response.feedback_text)
      end
    end
  end
end
