require 'rails_helper'

RSpec.describe 'Reports API', type: :request do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let(:inbox_member) { create(:inbox_member, user: user, inbox: inbox) }

  before do
    create_list(:conversation, 10, account: account, inbox: inbox,
                                   assignee: user, created_at: Time.zone.today)
  end

  describe 'GET /api/v2/accounts/:account_id/reports/account' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/account"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'return timeseries metrics' do
        params = {
          metric: 'conversations_count',
          type: :account,
          since: Time.zone.today.to_time.to_i.to_s,
          until: Time.zone.today.to_time.to_i.to_s
        }

        get "/api/v2/accounts/#{account.id}/reports/account",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        current_day_metric = json_response.select { |x| x['timestamp'] == Time.zone.today.to_time.to_i }
        expect(current_day_metric.length).to eq(1)
        expect(current_day_metric[0]['value']).to eq(10)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/account_summary' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/account_summary"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns summary metrics' do
        params = {
          type: :account,
          since: Time.zone.today.to_time.to_i.to_s,
          until: Time.zone.today.to_time.to_i.to_s
        }

        get "/api/v2/accounts/#{account.id}/reports/account_summary",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['conversations_count']).to eq(10)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/agents' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/agents.csv"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      params = {
        since: 30.days.ago.to_i.to_s,
        until: Time.zone.today.to_time.to_i.to_s
      }

      it 'returns summary' do
        get "/api/v2/accounts/#{account.id}/reports/agents.csv",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      params = {
        since: 30.days.ago.to_i.to_s,
        until: Time.zone.today.to_time.to_i.to_s
      }

      it 'returns summary' do
        get "/api/v2/accounts/#{account.id}/reports/inboxes",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end
end
