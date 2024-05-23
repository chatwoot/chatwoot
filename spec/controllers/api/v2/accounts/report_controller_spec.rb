require 'rails_helper'

RSpec.describe 'Reports API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let(:inbox_member) { create(:inbox_member, user: user, inbox: inbox) }
  let(:default_timezone) { 'UTC' }
  let(:start_of_today) { Time.current.in_time_zone(default_timezone).beginning_of_day.to_i }
  let(:end_of_today) { Time.current.in_time_zone(default_timezone).end_of_day.to_i }
  let(:params) { { timezone_offset: Time.zone.utc_offset } }
  let(:new_account) { create(:account) }

  before do
    create_list(:conversation, 10, account: account, inbox: inbox,
                                   assignee: user, created_at: Time.current.in_time_zone(default_timezone).to_date)
  end

  describe 'GET /api/v2/accounts/:account_id/reports' do
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
          since: start_of_today.to_s,
          until: end_of_today.to_s
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
        json_response = response.parsed_body

        current_day_metric = json_response.select { |x| x['timestamp'] == start_of_today }
        expect(current_day_metric.length).to eq(1)
        expect(current_day_metric[0]['value']).to eq(10)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/conversations' do
    context 'when it is an authenticated user' do
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
        json_response = response.parsed_body

        expect(json_response['open']).to eq(11)
        expect(json_response['unattended']).to eq(11)
        expect(json_response['unassigned']).to eq(1)
      end

      it 'return conversation metrics for user in account level' do
        create_list(:conversation, 2, account: account, inbox: inbox,
                                      assignee: admin, created_at: Time.zone.today)
        create_list(:conversation, 2, account: new_account, inbox: inbox,
                                      assignee: admin, created_at: Time.zone.today)

        get "/api/v2/accounts/#{account.id}/reports/conversations",
            params: {
              type: :agent
            },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body
        expect(json_response.blank?).to be false
        user_metrics = json_response.find { |item| item['name'] == admin[:name] }
        expect(user_metrics.present?).to be true

        expect(user_metrics['metric']['open']).to eq(2)
        expect(user_metrics['metric']['unattended']).to eq(2)
      end
    end

    context 'when an agent1 associated to conversation having first reply from agent2' do
      let(:listener) { ReportingEventListener.instance }
      let(:account) { create(:account) }
      let(:agent2) { create(:user, account: account, role: :agent) }

      it 'returns unattended conversation count zero for agent1' do
        create(:inbox_member, user: agent, inbox: inbox)
        create(:inbox_member, user: agent2, inbox: inbox)
        conversation = create(:conversation, account: account,
                                             inbox: inbox, assignee: agent2)

        create(:message, message_type: 'incoming', content: 'Hi',
                         account: account, inbox: inbox,
                         conversation: conversation)
        first_reply_message = create(:message, message_type: 'outgoing', content: 'Hi',
                                               account: account, inbox: inbox, sender: agent2,
                                               conversation: conversation)

        event = Events::Base.new('first.reply.created', Time.zone.now, message: first_reply_message)
        listener.first_reply_created(event)

        conversation.assignee_id = agent.id
        conversation.save!

        get "/api/v2/accounts/#{account.id}/reports/conversations",
            params: {
              type: :agent
            },
            headers: admin.create_new_auth_token,
            as: :json

        json_response = response.parsed_body
        user_metrics = json_response.find { |item| item['name'] == agent[:name] }
        expect(user_metrics.present?).to be true

        expect(user_metrics['metric']['open']).to eq(1)
        expect(user_metrics['metric']['unattended']).to eq(0)
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
          since: start_of_today.to_s,
          until: end_of_today.to_s
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
        json_response = response.parsed_body

        expect(json_response['conversations_count']).to eq(10)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/bot_summary' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/bot_summary"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          type: :account,
          since: start_of_today.to_s,
          until: end_of_today.to_s
        )
      end

      it 'returns unauthorized for agents' do
        get "/api/v2/accounts/#{account.id}/reports/bot_summary",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns bot summary metrics' do
        get "/api/v2/accounts/#{account.id}/reports/bot_summary",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['bot_resolutions_count']).to eq(0)
        expect(json_response['bot_handoffs_count']).to eq(0)
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
          until: end_of_today.to_s
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

    context 'when an agent has access to multiple accounts' do
      let(:account1) { create(:account) }
      let(:account2) { create(:account) }

      let(:params) do
        super().merge(
          type: :agent,
          since: 30.days.ago.to_i.to_s,
          until: end_of_today.to_s
        )
      end

      it 'returns agent metrics from the current account' do
        admin1 = create(:user, account: account1, role: :administrator)
        inbox1 = create(:inbox, account: account1)
        inbox2 = create(:inbox, account: account2)

        create(:account_user, user: admin1, account: account2)
        create(:conversation, account: account1, inbox: inbox1,
                              assignee: admin1, created_at: Time.zone.today - 2.days)
        create(:conversation, account: account2, inbox: inbox2,
                              assignee: admin1, created_at: Time.zone.today - 2.days)

        get "/api/v2/accounts/#{account1.id}/reports/summary",
            params: params.merge({ id: admin1.id }),
            headers: admin1.create_new_auth_token

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body
        expect(json_response['conversations_count']).to eq(1)
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
          until: end_of_today.to_s
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
          until: end_of_today.to_s
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
          until: end_of_today.to_s
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

  describe 'GET /api/v2/accounts/:account_id/reports/conversation_traffic' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/conversation_traffic.csv"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          since: 7.days.ago.to_i.to_s,
          until: end_of_today.to_s
        )
      end

      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/conversation_traffic.csv",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns values' do
        get "/api/v2/accounts/#{account.id}/reports/conversation_traffic.csv",
            params: params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/bot_metrics' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports/bot_metrics"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          since: 7.days.ago.to_i.to_s,
          until: end_of_today.to_s
        )
      end

      it 'returns unauthorized if the user is an agent' do
        get "/api/v2/accounts/#{account.id}/reports/bot_metrics",
            params: params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns values' do
        expect(V2::Reports::BotMetricsBuilder).to receive(:new).and_call_original
        get "/api/v2/accounts/#{account.id}/reports/bot_metrics",
            params: params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.keys).to match_array(%w[conversation_count message_count resolution_rate handoff_rate])
      end
    end
  end
end
