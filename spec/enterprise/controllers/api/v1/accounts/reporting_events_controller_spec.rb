require 'rails_helper'

RSpec.describe 'Enterprise Reporting Events API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  describe 'GET /api/v1/accounts/{account.id}/reporting_events' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/reporting_events",
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated normal agent user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/reporting_events",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      before do
        create(:reporting_event,
               account: account,
               conversation: conversation,
               inbox: inbox,
               user: agent,
               name: 'first_response',
               value: 120,
               created_at: 3.days.ago)
        create(:reporting_event,
               account: account,
               conversation: conversation,
               inbox: inbox,
               user: agent,
               name: 'resolution',
               value: 300,
               created_at: 2.days.ago)
        create(:reporting_event,
               account: account,
               conversation: conversation,
               inbox: inbox,
               user: agent,
               name: 'reply_time',
               value: 45,
               created_at: 1.day.ago)
      end

      it 'fetches reporting events with pagination' do
        get "/api/v1/accounts/#{account.id}/reporting_events",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        # Check structure and pagination
        expect(json_response).to have_key('payload')
        expect(json_response).to have_key('meta')
        expect(json_response['meta']['count']).to eq(3)

        # Check events are sorted by created_at desc (newest first)
        events = json_response['payload']
        expect(events.size).to eq(3)
        expect(events.first['name']).to eq('reply_time')
        expect(events.last['name']).to eq('first_response')
      end

      it 'filters reporting events by date range using since and until' do
        get "/api/v1/accounts/#{account.id}/reporting_events",
            params: { since: 2.5.days.ago.to_time.to_i.to_s, until: 1.5.days.ago.to_time.to_i.to_s },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['meta']['count']).to eq(1)
        expect(json_response['payload'].first['name']).to eq('resolution')
      end

      it 'filters reporting events by inbox_id' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)
        create(:reporting_event,
               account: account,
               conversation: other_conversation,
               inbox: other_inbox,
               user: agent,
               name: 'other_inbox_event')

        get "/api/v1/accounts/#{account.id}/reporting_events",
            params: { inbox_id: inbox.id },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['meta']['count']).to eq(3)
        expect(json_response['payload'].map { |e| e['name'] }).not_to include('other_inbox_event')
      end

      it 'filters reporting events by user_id (agent)' do
        other_agent = create(:user, account: account, role: :agent)
        create(:reporting_event,
               account: account,
               conversation: conversation,
               inbox: inbox,
               user: other_agent,
               name: 'other_agent_event')

        get "/api/v1/accounts/#{account.id}/reporting_events",
            params: { user_id: agent.id },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['meta']['count']).to eq(3)
        expect(json_response['payload'].map { |e| e['name'] }).not_to include('other_agent_event')
      end

      it 'filters reporting events by name' do
        get "/api/v1/accounts/#{account.id}/reporting_events",
            params: { name: 'first_response' },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['meta']['count']).to eq(1)
        expect(json_response['payload'].first['name']).to eq('first_response')
      end

      it 'supports combining multiple filters' do
        # Create more test data
        other_conversation = create(:conversation, account: account, inbox: inbox, assignee: agent)
        create(:reporting_event,
               account: account,
               conversation: other_conversation,
               inbox: inbox,
               user: agent,
               name: 'first_response',
               value: 90,
               created_at: 2.days.ago)

        get "/api/v1/accounts/#{account.id}/reporting_events",
            params: {
              inbox_id: inbox.id,
              user_id: agent.id,
              name: 'first_response',
              since: 4.days.ago.to_time.to_i.to_s,
              until: Time.zone.now.to_time.to_i.to_s
            },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response['meta']['count']).to eq(2)
        expect(json_response['payload'].map { |e| e['name'] }).to all(eq('first_response'))
      end

      context 'with pagination' do
        before do
          # Create more events to test pagination
          30.times do |i|
            create(:reporting_event,
                   account: account,
                   conversation: conversation,
                   inbox: inbox,
                   user: agent,
                   name: "event_#{i}",
                   created_at: i.hours.ago)
          end
        end

        it 'returns 25 events per page by default' do
          get "/api/v1/accounts/#{account.id}/reporting_events",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          expect(json_response['payload'].size).to eq(25)
          expect(json_response['meta']['count']).to eq(33) # 30 + 3 original events
          expect(json_response['meta']['current_page']).to eq(1)
        end

        it 'supports page navigation' do
          get "/api/v1/accounts/#{account.id}/reporting_events",
              params: { page: 2 },
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body

          expect(json_response['payload'].size).to eq(8) # Remaining events
          expect(json_response['meta']['current_page']).to eq(2)
        end
      end
    end
  end
end
