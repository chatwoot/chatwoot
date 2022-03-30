require 'rails_helper'

RSpec.describe 'Reports API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let(:inbox_member) { create(:inbox_member, user: user, inbox: inbox) }
  let(:default_timezone) { ActiveSupport::TimeZone[0]&.name }
  let(:date_timestamp) { Time.current.in_time_zone(default_timezone).beginning_of_day.to_i }
  let(:params) { { timezone_offset: Time.zone.utc_offset } }

  before do
    create_list(:conversation, 10, account: account, inbox: inbox,
                                   assignee: user, created_at: Time.zone.today)
  end

  describe 'GET /api/v2/accounts/:account_id/reports/account' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          metric: 'conversations_count',
          type: :account,
          since: date_timestamp.to_s,
          until: date_timestamp.to_s
        )
      end

      it 'returns unauthorized for agents' do
        get "/api/v2/accounts/#{account.id}/reports",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'return timeseries metrics' do
        get "/api/v2/accounts/#{account.id}/reports",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        current_day_metric = json_response.select { |x| x['timestamp'] == date_timestamp }
        expect(current_day_metric.length).to eq(1)
        expect(current_day_metric[0]['value']).to eq(10)
      end

      it 'return conversation metrics in account level' do
        unassigned_conversation = create(:conversation, account: account, inbox: inbox,
                                                        assignee: nil, created_at: Time.zone.today)
        unassigned_conversation.save!

        get "/api/v2/accounts/#{account.id}/reports/conversations",
            params: {
              type: :account
            },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['open']).to eq(11)
        expect(json_response['unattended']).to eq(11)
        expect(json_response['unassigned']).to eq(1)
      end

      it 'return conversation metrics for user in account level' do
        create_list(:conversation, 2, account: account, inbox: inbox,
                                      assignee: admin, created_at: Time.zone.today)

        get "/api/v2/accounts/#{account.id}/reports/conversations",
            params: {
              type: :agent
            },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response.blank?).to be false
        user_metrics = json_response.find { |item| item['user']['name'] == admin[:name] }
        expect(user_metrics.present?).to be true

        expect(user_metrics['metric']['open']).to eq(2)
        expect(user_metrics['metric']['unattended']).to eq(2)
      end

      it 'return conversation metrics for specific user in account level' do
        create_list(:conversation, 2, account: account, inbox: inbox,
                                      assignee: admin, created_at: Time.zone.today)

        get "/api/v2/accounts/#{account.id}/reports/conversations",
            params: {
              type: :agent,
              user_id: user.id
            },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response.blank?).to be false
        expect(json_response[0]['metric']['open']).to eq(10)
        expect(json_response[0]['metric']['unattended']).to eq(10)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/summary' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/summary"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          type: :account,
          since: date_timestamp.to_s,
          until: date_timestamp.to_s
        )
      end

      it 'returns unauthorized for agents' do
        get "/api/v2/accounts/#{account.id}/reports/summary",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns summary metrics' do
        get "/api/v2/accounts/#{account.id}/reports/summary",
            params: params,
            headers: admin.create_new_auth_token,
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
      let(:params) do
        super().merge(
          since: 30.days.ago.to_i.to_s,
          until: date_timestamp.to_s
        )
      end

      it 'returns unauthorized for agents' do
        get "/api/v2/accounts/#{account.id}/reports/agents.csv",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns summary' do
        get "/api/v2/accounts/#{account.id}/reports/agents.csv",
            params: params,
            headers: admin.create_new_auth_token

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
      let(:params) do
        super().merge(
          since: 30.days.ago.to_i.to_s,
          until: date_timestamp.to_s
        )
      end

      it 'returns unauthorized for inboxes' do
        get "/api/v2/accounts/#{account.id}/reports/inboxes",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns summary' do
        get "/api/v2/accounts/#{account.id}/reports/inboxes",
            params: params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/labels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/labels.csv"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          since: 30.days.ago.to_i.to_s,
          until: date_timestamp.to_s
        )
      end

      it 'returns unauthorized for labels' do
        get "/api/v2/accounts/#{account.id}/reports/labels.csv",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns summary' do
        get "/api/v2/accounts/#{account.id}/reports/labels.csv",
            params: params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/teams' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/teams.csv"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          since: 30.days.ago.to_i.to_s,
          until: date_timestamp.to_s
        )
      end

      it 'returns unauthorized for teams' do
        get "/api/v2/accounts/#{account.id}/reports/teams.csv",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns summary' do
        get "/api/v2/accounts/#{account.id}/reports/teams.csv",
            params: params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end
end
