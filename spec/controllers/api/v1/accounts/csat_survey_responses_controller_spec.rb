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
        expect(JSON.parse(response.body).first['feedback_message']).to eq(csat_survey_response.feedback_message)
      end

      it 'filters csat responsed based on a date range' do
        csat_10_days_ago = create(:csat_survey_response, account: account, created_at: 10.days.ago)
        csat_3_days_ago = create(:csat_survey_response, account: account, created_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/csat_survey_responses",
            params: { since: 5.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.pluck('id')).to include(csat_3_days_ago.id)
        expect(response_data.pluck('id')).not_to include(csat_10_days_ago.id)
      end
    end
  end
end
