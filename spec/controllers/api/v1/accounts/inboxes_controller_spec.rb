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

      context 'when provider_config' do
        let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }

        it 'returns provider config attributes for admin' do
          get "/api/v1/accounts/#{account.id}/inboxes",
              headers: admin.create_new_auth_token,
              as: :json
          expect(JSON.parse(response.body)['payload'].last.key?('provider_config')).to eq(true)
        end

        it 'will not return provider config for agent' do
          get "/api/v1/accounts/#{account.id}/inboxes",
              headers: agent.create_new_auth_token,
              as: :json

          expect(JSON.parse(response.body)['payload'].last.key?('provider_config')).to eq(false)
        end
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

      let!(:campaign) { create(:campaign, account: account, inbox: inbox, trigger_rules: { url: 'https://test.com' }) }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/campaigns",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns all campaigns belonging to the inbox to administrators' do
        # create a random campaign
        create(:campaign, account: account, trigger_rules: { url: 'https://test.com' })
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

      it 'creates an api inbox when administrator' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { name: 'API Inbox', channel: { type: 'api', webhook_url: 'http://test.com' } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('API Inbox')
      end

      it 'creates a line inbox when administrator' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { name: 'Line Inbox',
                       channel: { type: 'line', line_channel_id: SecureRandom.uuid, line_channel_secret: SecureRandom.uuid,
                                  line_channel_token: SecureRandom.uuid } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Line Inbox')
        expect(response.body).to include('callback_webhook_url')
      end

      it 'creates a sms inbox when administrator' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { name: 'Sms Inbox',
                       channel: { type: 'sms', phone_number: '+123456789', provider_config: { test: 'test' } } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Sms Inbox')
        expect(response.body).to include('+123456789')
      end

      it 'creates the webwidget inbox that allow messages after conversation is resolved' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['allow_messages_after_resolved']).to be true
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
      let(:valid_params) { { name: 'new test inbox', enable_auto_assignment: false } }

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
        expect(JSON.parse(response.body)['name']).to eq 'new test inbox'
      end

      it 'updates api inbox when administrator' do
        api_channel = create(:channel_api, account: account)
        api_inbox = create(:inbox, channel: api_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{api_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { enable_auto_assignment: false, channel: { webhook_url: 'webhook.test', selected_feature_flags: [] } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(api_inbox.reload.enable_auto_assignment).to be_falsey
        expect(api_channel.reload.webhook_url).to eq('webhook.test')
      end

      it 'updates twitter inbox when administrator' do
        api_channel = create(:channel_twitter_profile, account: account, tweets_enabled: true)
        api_inbox = create(:inbox, channel: api_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{api_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { channel: { tweets_enabled: false } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(api_channel.reload.tweets_enabled).to eq(false)
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

      it 'updates email inbox with imap when administrator' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        imap_connection = double
        allow(Mail).to receive(:connection).and_return(imap_connection)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: {
                channel: {
                  imap_enabled: true,
                  imap_address: 'imap.gmail.com',
                  imap_port: 993,
                  imap_login: 'imaptest@gmail.com'
                }
              },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_channel.reload.imap_enabled).to be true
        expect(email_channel.reload.imap_address).to eq('imap.gmail.com')
        expect(email_channel.reload.imap_port).to eq(993)
      end

      it 'updates avatar when administrator' do
        # no avatar before upload
        expect(inbox.avatar.attached?).to eq(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: valid_params.merge(avatar: file),
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
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

      it 'updates the webwidget inbox to disallow the messages after conversation is resolved' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              params: valid_params.merge({ allow_messages_after_resolved: false }),
              as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.reload.allow_messages_after_resolved).to be_falsey
      end
    end

    context 'when an authenticated user updates email inbox' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:email_channel) { create(:channel_email, account: account) }
      let(:email_inbox) { create(:inbox, channel: email_channel, account: account) }

      it 'updates smtp configuration with starttls encryption' do
        smtp_connection = double
        allow(smtp_connection).to receive(:start).and_return(true)
        allow(smtp_connection).to receive(:finish).and_return(true)
        allow(smtp_connection).to receive(:respond_to?).and_return(true)
        allow(smtp_connection).to receive(:enable_starttls_auto).and_return(true)
        allow(Net::SMTP).to receive(:new).and_return(smtp_connection)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: {
                channel: {
                  smtp_enabled: true,
                  smtp_address: 'smtp.gmail.com',
                  smtp_port: 587,
                  smtp_login: 'smtptest@gmail.com',
                  smtp_enable_starttls_auto: true,
                  smtp_openssl_verify_mode: 'peer'
                }
              },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_channel.reload.smtp_enabled).to be true
        expect(email_channel.reload.smtp_address).to eq('smtp.gmail.com')
        expect(email_channel.reload.smtp_port).to eq(587)
        expect(email_channel.reload.smtp_enable_starttls_auto).to be true
        expect(email_channel.reload.smtp_openssl_verify_mode).to eq('peer')
      end

      it 'updates smtp configuration with ssl/tls encryption' do
        smtp_connection = double
        allow(smtp_connection).to receive(:start).and_return(true)
        allow(smtp_connection).to receive(:finish).and_return(true)
        allow(smtp_connection).to receive(:respond_to?).and_return(true)
        allow(smtp_connection).to receive(:enable_tls).and_return(true)
        allow(Net::SMTP).to receive(:new).and_return(smtp_connection)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: {
                channel: {
                  smtp_enabled: true,
                  smtp_address: 'smtp.gmail.com',
                  smtp_login: 'smtptest@gmail.com',
                  smtp_port: 587,
                  smtp_enable_ssl_tls: true,
                  smtp_openssl_verify_mode: 'none'
                }
              },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_channel.reload.smtp_enabled).to be true
        expect(email_channel.reload.smtp_address).to eq('smtp.gmail.com')
        expect(email_channel.reload.smtp_port).to eq(587)
        expect(email_channel.reload.smtp_enable_ssl_tls).to be true
        expect(email_channel.reload.smtp_openssl_verify_mode).to eq('none')
      end

      it 'updates smtp configuration with authentication mechanism' do
        smtp_connection = double
        allow(smtp_connection).to receive(:start).and_return(true)
        allow(smtp_connection).to receive(:finish).and_return(true)
        allow(smtp_connection).to receive(:respond_to?).and_return(true)
        allow(smtp_connection).to receive(:enable_starttls_auto).and_return(true)
        allow(Net::SMTP).to receive(:new).and_return(smtp_connection)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: {
                channel: {
                  smtp_enabled: true,
                  smtp_address: 'smtp.gmail.com',
                  smtp_port: 587,
                  smtp_email: 'smtptest@gmail.com',
                  smtp_authentication: 'plain'
                }
              },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_channel.reload.smtp_enabled).to be true
        expect(email_channel.reload.smtp_address).to eq('smtp.gmail.com')
        expect(email_channel.reload.smtp_port).to eq(587)
        expect(email_channel.reload.smtp_authentication).to eq('plain')
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
