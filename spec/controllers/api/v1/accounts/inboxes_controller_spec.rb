require 'rails_helper'

RSpec.describe 'Inboxes API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:inbox) { create(:inbox, account: account) }

      before do
        create(:inbox, account: account)
        create(:inbox_member, user: agent, inbox: inbox)
      end

      it 'returns all inboxes of current_account as administrator' do
        get "/api/v1/accounts/#{account.id}/inboxes",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(2)
      end

      it 'returns only assigned inboxes of current_account as agent' do
        get "/api/v1/accounts/#{account.id}/inboxes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:inbox) { create(:inbox, account: account) }

      it 'returns unauthorized for an agent who is not assigned' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns the inbox if administrator' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(inbox.id)
      end

      it 'returns the inbox if assigned inbox is assigned as agent' do
        create(:inbox_member, user: agent, inbox: inbox)
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(inbox.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/assignable_agents' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignable_agents"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create(:inbox_member, user: agent, inbox: inbox)
      end

      it 'returns all assignable inbox members along with administrators' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignable_agents",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)[:payload]
        expect(response_data.size).to eq(2)
        expect(response_data.pluck(:role)).to include('agent', 'administrator')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/campaigns' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/campaigns"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      let!(:campaign) { create(:campaign, account: account, inbox: inbox) }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/campaigns",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns all campaigns belonging to the inbox to administrators' do
        # create a random campaign
        create(:campaign, account: account)
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/campaigns",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body.first[:id]).to eq(campaign.display_id)
        expect(body.length).to eq(1)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/inboxes/{inbox.id}/avatar' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/avatar"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create(:inbox_member, user: agent, inbox: inbox)
        inbox.avatar.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      end

      it 'delete inbox avatar for administrator user' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/avatar",
               headers: admin.create_new_auth_token,
               as: :json

        expect { inbox.avatar.attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_http_status(:success)
      end

      it 'returns unauthorized for agent user' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/avatar",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/inboxes/:id' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'deletes inbox' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect { inbox.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it 'is unable to delete inbox of another account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)

        delete "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'is unable to delete inbox as agent' do
        agent = create(:user, account: account, role: :agent)

        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) { { name: 'test', channel: { type: 'web_widget', website_url: 'test.com' } } }

      it 'will not create inbox for agent' do
        agent = create(:user, account: account, role: :agent)

        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a webwidget inbox when administrator' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('test.com')
      end

      it 'creates a email inbox when administrator' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { name: 'test', channel: { type: 'email', email: 'test@test.com' } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('test@test.com')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/inboxes/:id' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) { {  enable_auto_assignment: false, channel: { website_url: 'test.com' } } }

      it 'will not update inbox for agent' do
        agent = create(:user, account: account, role: :agent)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: agent.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates inbox when administrator' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.reload.enable_auto_assignment).to be_falsey
      end

      it 'updates api inbox when administrator' do
        api_channel = create(:channel_api, account: account)
        api_inbox = create(:inbox, channel: api_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{api_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { enable_auto_assignment: false, channel: { webhook_url: 'webhook.test' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(api_inbox.reload.enable_auto_assignment).to be_falsey
        expect(api_channel.reload.webhook_url).to eq('webhook.test')
      end

      it 'updates email inbox when administrator' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { enable_auto_assignment: false, channel: { email: 'emailtest@email.test' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_inbox.reload.enable_auto_assignment).to be_falsey
        expect(email_channel.reload.email).to eq('emailtest@email.test')
      end

      it 'updates avatar when administrator' do
        # no avatar before upload
        expect(inbox.avatar.attached?).to eq(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: valid_params.merge(avatar: file),
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.body).to include('test.com')
        inbox.reload
        expect(inbox.avatar.attached?).to eq(true)
      end

      it 'updates working hours when administrator' do
        params = {
          working_hours: [{ 'day_of_week' => 0, 'open_hour' => 9, 'open_minutes' => 0, 'close_hour' => 17, 'close_minutes' => 0 }],
          working_hours_enabled: true,
          out_of_office_message: 'hello'
        }
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: valid_params.merge(params),
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        inbox.reload
        expect(inbox.reload.weekly_schedule.find { |schedule| schedule['day_of_week'] == 0 }['open_hour']).to eq 9
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/agent_bot' do
    let(:inbox) { create(:inbox, account: account) }

    before do
      create(:inbox_member, user: agent, inbox: inbox)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/agent_bot"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns empty when no agent bot is present' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/agent_bot",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        inbox_data = JSON.parse(response.body, symbolize_names: true)
        expect(inbox_data[:agent_bot].blank?).to eq(true)
      end

      it 'returns the agent bot attached to the inbox' do
        agent_bot = create(:agent_bot)
        create(:agent_bot_inbox, agent_bot: agent_bot, inbox: inbox)
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/agent_bot",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        inbox_data = JSON.parse(response.body, symbolize_names: true)
        expect(inbox_data[:agent_bot][:name]).to eq agent_bot.name
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/:id/set_agent_bot' do
    let(:inbox) { create(:inbox, account: account) }
    let(:agent_bot) { create(:agent_bot) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_agent_bot"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) { { agent_bot: agent_bot.id } }

      it 'sets the agent bot' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_agent_bot",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.reload.agent_bot.id).to eq agent_bot.id
      end

      it 'throw error when invalid agent bot id' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_agent_bot",
             headers: admin.create_new_auth_token,
             params: { agent_bot: 0 },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'disconnects the agent bot' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_agent_bot",
             headers: admin.create_new_auth_token,
             params: { agent_bot: nil },
             as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.reload.agent_bot).to be_falsey
      end

      it 'will not update agent bot when its an agent' do
        agent = create(:user, account: account, role: :agent)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_agent_bot",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
