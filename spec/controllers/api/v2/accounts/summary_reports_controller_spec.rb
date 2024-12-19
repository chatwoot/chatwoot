require 'rails_helper'

RSpec.describe 'Summary Reports API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:default_timezone) { ActiveSupport::TimeZone[0]&.name }
  let(:start_of_today) { Time.current.in_time_zone(default_timezone).beginning_of_day.to_i }
  let(:end_of_today) { Time.current.in_time_zone(default_timezone).end_of_day.to_i }

  describe 'GET /api/v2/accounts/:account_id/summary_reports/agent' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/summary_reports/agent"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          since: start_of_today.to_s,
          until: end_of_today.to_s,
          business_hours: true
        }
      end

      it 'returns unauthorized for agents' do
        get "/api/v2/accounts/#{account.id}/summary_reports/agent",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'calls V2::Reports::AgentSummaryBuilder with the right params if the user is an admin' do
        agent_summary_builder = double
        allow(V2::Reports::AgentSummaryBuilder).to receive(:new).and_return(agent_summary_builder)
        allow(agent_summary_builder).to receive(:build).and_return([{ id: 1, conversations_count: 110 }])

        get "/api/v2/accounts/#{account.id}/summary_reports/agent",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(V2::Reports::AgentSummaryBuilder).to have_received(:new).with(account: account, params: params)
        expect(agent_summary_builder).to have_received(:build)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(1)
        expect(json_response.first['conversations_count']).to eq(110)
        expect(json_response.first['avg_reply_time']).to be_nil
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/summary_reports/inbox' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/summary_reports/inbox"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          since: start_of_today.to_s,
          until: end_of_today.to_s,
          business_hours: true
        }
      end

      it 'returns unauthorized for inbox' do
        get "/api/v2/accounts/#{account.id}/summary_reports/inbox",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'calls V2::Reports::InboxSummaryBuilder with the right params if the user is an admin' do
        inbox_summary_builder = double
        allow(V2::Reports::InboxSummaryBuilder).to receive(:new).and_return(inbox_summary_builder)
        allow(inbox_summary_builder).to receive(:build).and_return([{ id: 1, conversations_count: 110 }])

        get "/api/v2/accounts/#{account.id}/summary_reports/inbox",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(V2::Reports::InboxSummaryBuilder).to have_received(:new).with(account: account, params: params)
        expect(inbox_summary_builder).to have_received(:build)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(1)
        expect(json_response.first['conversations_count']).to eq(110)
        expect(json_response.first['avg_reply_time']).to be_nil
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/summary_reports/team' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/summary_reports/team"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          since: start_of_today.to_s,
          until: end_of_today.to_s,
          business_hours: true
        }
      end

      it 'returns unauthorized for agents' do
        get "/api/v2/accounts/#{account.id}/summary_reports/team",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'calls V2::Reports::TeamSummaryBuilder with the right params if the user is an admin' do
        team_summary_builder = double
        allow(V2::Reports::TeamSummaryBuilder).to receive(:new).and_return(team_summary_builder)
        allow(team_summary_builder).to receive(:build).and_return([{ id: 1, conversations_count: 110 }])

        get "/api/v2/accounts/#{account.id}/summary_reports/team",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(V2::Reports::TeamSummaryBuilder).to have_received(:new).with(account: account, params: params)
        expect(team_summary_builder).to have_received(:build)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(1)
        expect(json_response.first['conversations_count']).to eq(110)
        expect(json_response.first['avg_reply_time']).to be_nil
      end
    end
  end
end
