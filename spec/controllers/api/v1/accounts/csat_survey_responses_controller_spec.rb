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

      it 'filters csat responses based on a date range' do
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

      it 'filters csat responses based on a date range and agent ids' do
        csat1_assigned_agent = create(:user, account: account, role: :agent)
        csat2_assigned_agent = create(:user, account: account, role: :agent)

        create(:csat_survey_response, account: account, created_at: 10.days.ago, assigned_agent: csat1_assigned_agent)
        create(:csat_survey_response, account: account, created_at: 3.days.ago, assigned_agent: csat2_assigned_agent)
        create(:csat_survey_response, account: account, created_at: 5.days.ago)

        get "/api/v1/accounts/#{account.id}/csat_survey_responses",
            params: { since: 11.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s,
                      user_ids: [csat1_assigned_agent.id, csat2_assigned_agent.id] },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data.size).to eq 2
      end

      it 'returns csat responses even if the agent is deleted from account' do
        deleted_agent_csat = create(:csat_survey_response, account: account, assigned_agent: agent)
        deleted_agent_csat.assigned_agent.account_users.destroy_all

        get "/api/v1/accounts/#{account.id}/csat_survey_responses",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/csat_survey_responses/metrics' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses/metrics"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses/metrics",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns csat metrics for administrators' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses/metrics",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['total_count']).to eq 1
        expect(response_data['total_sent_messages_count']).to eq 0
        expect(response_data['ratings_count']).to eq({ '1' => 1 })
      end

      it 'filters csat metrics based on a date range' do
        create(:csat_survey_response, account: account, created_at: 10.days.ago)
        create(:csat_survey_response, account: account, created_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/csat_survey_responses/metrics",
            params: { since: 5.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['total_count']).to eq 1
        expect(response_data['total_sent_messages_count']).to eq 0
        expect(response_data['ratings_count']).to eq({ '1' => 1 })
      end

      it 'filters csat metrics based on a date range and agent ids' do
        csat1_assigned_agent = create(:user, account: account, role: :agent)
        csat2_assigned_agent = create(:user, account: account, role: :agent)

        create(:csat_survey_response, account: account, created_at: 10.days.ago, assigned_agent: csat1_assigned_agent)
        create(:csat_survey_response, account: account, created_at: 3.days.ago, assigned_agent: csat2_assigned_agent)
        create(:csat_survey_response, account: account, created_at: 5.days.ago)

        get "/api/v1/accounts/#{account.id}/csat_survey_responses/metrics",
            params: { since: 11.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s,
                      user_ids: [csat1_assigned_agent.id, csat2_assigned_agent.id] },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['total_count']).to eq 2
        expect(response_data['total_sent_messages_count']).to eq 0
        expect(response_data['ratings_count']).to eq({ '1' => 2 })
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/csat_survey_responses/download' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses/download"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { since: 5.days.ago.to_time.to_i.to_s, until: Time.zone.tomorrow.to_time.to_i.to_s } }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses/download",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns summary' do
        get "/api/v1/accounts/#{account.id}/csat_survey_responses/download",
            params: params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)

        content = CSV.parse(response.body)
        # Check rating from CSAT Row
        expect(content[1][1]).to eq '1'
        expect(content.length).to eq 3
      end
    end
  end
end
