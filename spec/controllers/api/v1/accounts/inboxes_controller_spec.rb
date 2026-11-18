require 'rails_helper'

RSpec.describe 'Inboxes API', type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'POST /api/v1/accounts/{account.id}/inboxes/{inbox.id}/rotate_hmac_token' do
    let(:channel) { create(:channel_widget, account: account) }
    let(:inbox) { channel.inbox }
    let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/rotate_hmac_token" }

    [:channel_widget, :channel_api].each do |channel_factory|
      context "with #{channel_factory}" do
        let(:channel) { create(channel_factory, account: account) }

        it 'rotates the persisted token and returns the updated inbox for an administrator' do
          old_token = channel.hmac_token

          post url, headers: admin.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(channel.reload.hmac_token).to be_present
          expect(channel.hmac_token).not_to eq(old_token)
          expect(response.parsed_body).to include('id' => inbox.id, 'hmac_token' => channel.hmac_token)
        end

        it 'rejects an assigned agent without changing the token' do
          create(:inbox_member, user: agent, inbox: inbox)

          expect do
            post url, headers: agent.create_new_auth_token, as: :json
          end.not_to(change { channel.reload.hmac_token })

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    it 'rejects unauthenticated requests without changing the token' do
      expect do
        post url, as: :json
      end.not_to(change { channel.reload.hmac_token })

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not rotate an inbox belonging to another account' do
      other_inbox = create(:inbox)

      expect do
        post "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}/rotate_hmac_token",
             headers: admin.create_new_auth_token, as: :json
      end.not_to(change { other_inbox.channel.reload.hmac_token })

      expect(response).to have_http_status(:not_found)
    end

    context 'with an unsupported channel' do
      let(:inbox) { create(:inbox, :with_email, account: account) }

      it 'returns not found without updating the channel' do
        expect do
          post url, headers: admin.create_new_auth_token, as: :json
        end.not_to(change { inbox.channel.reload.attributes })

        expect(response).to have_http_status(:not_found)
      end
    end
  end

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
        expect(response).to conform_schema(200)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(2)
      end

      it 'does not include branded email layout in index responses' do
        email_inbox = create(:inbox, :with_email, account: account)
        create(:email_template, :layout, account: account, inbox: email_inbox, body: '<html>{{ content_for_layout }} Branded</html>')

        get "/api/v1/accounts/#{account.id}/inboxes",
            headers: admin.create_new_auth_token,
            as: :json

        inbox_data = JSON.parse(response.body, symbolize_names: true)[:payload].find { |item| item[:id] == email_inbox.id }
        expect(inbox_data).not_to have_key(:branded_email_layout)
      end

      it 'returns only assigned inboxes of current_account as agent' do
        get "/api/v1/accounts/#{account.id}/inboxes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(1)
      end

      it 'returns safe channel identifiers for assigned inboxes' do
        allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
        instagram_channel = create(:channel_instagram, account: account, instagram_id: 'instagram-id', provider_name: 'acme_support')
        tiktok_channel = create(:channel_tiktok, account: account, business_id: 'tiktok-business-id', provider_name: 'acme_tiktok')
        facebook_inbox = create(
          :inbox,
          account: account,
          channel: build(:channel_facebook_page, account: account, inbox: nil, provider_name: 'Acme Facebook')
        )
        twitter_inbox = create(:inbox, account: account, channel: create(:channel_twitter_profile, account: account, profile_id: 'x-profile-id'))
        line_inbox = create(:inbox, account: account,
                                    channel: build(:channel_line, account: account, inbox: nil, line_channel_id: 'line-channel-id'))
        [instagram_channel.inbox, tiktok_channel.inbox, facebook_inbox, twitter_inbox, line_inbox].each do |channel_inbox|
          create(:inbox_member, user: agent, inbox: channel_inbox)
        end

        get "/api/v1/accounts/#{account.id}/inboxes",
            headers: agent.create_new_auth_token,
            as: :json

        inboxes_by_id = response.parsed_body['payload'].index_by { |item| item['id'] }
        expect(inboxes_by_id[instagram_channel.inbox.id]['provider_name']).to eq('acme_support')
        expect(inboxes_by_id[tiktok_channel.inbox.id]['business_id']).to eq('tiktok-business-id')
        expect(inboxes_by_id[tiktok_channel.inbox.id]['provider_name']).to eq('acme_tiktok')
        expect(inboxes_by_id[facebook_inbox.id]['provider_name']).to eq('Acme Facebook')
        expect(inboxes_by_id[twitter_inbox.id]['profile_id']).to eq('x-profile-id')
        expect(inboxes_by_id[line_inbox.id]['line_channel_id']).to eq('line-channel-id')
      end

      context 'when provider_config' do
        let(:inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }

        it 'returns provider config attributes for admin' do
          get "/api/v1/accounts/#{account.id}/inboxes",
              headers: admin.create_new_auth_token,
              as: :json
          expect(response.body).to include('provider_config')
        end

        it 'will not return provider config for agent' do
          get "/api/v1/accounts/#{account.id}/inboxes",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response.body).not_to include('provider_config')
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
        expect(response).to conform_schema(200)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(inbox.id)
      end

      it 'exposes reconnect for a Unified Login inbox after its finite token expires' do
        channel = create(:channel_instagram, account: account, auth_type: 'unified_login', expires_at: 1.hour.from_now)
        headers = admin.create_new_auth_token
        url = "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}"
        get url, headers: headers, as: :json
        expect(response.parsed_body['reauthorization_required']).to be(false)

        travel_to(2.hours.from_now) do
          channel.access_token
          get url, headers: headers, as: :json
          expect(response).to have_http_status(:success)
          expect(response.parsed_body['reauthorization_required']).to be(true)
        end
      end

      it 'returns reauthorization_required for embedded signup whatsapp channel when reauth required' do
        whatsapp_channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false,
                                                     validate_provider_config: false)
        whatsapp_inbox = create(:inbox, channel: whatsapp_channel, account: account)
        whatsapp_channel.prompt_reauthorization!

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['reauthorization_required']).to be(true)
      end

      it 'returns only the configured state for an embedded signup WhatsApp business management token' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        whatsapp_channel = create(
          :channel_whatsapp,
          account: account,
          provider: 'whatsapp_cloud',
          business_management_token: 'business-token',
          sync_templates: false,
          validate_provider_config: false
        )
        whatsapp_inbox = create(:inbox, channel: whatsapp_channel, account: account)

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['business_management_token_configured']).to be(true)
        expect(response.parsed_body).not_to have_key('business_management_token')
        expect(response.body).not_to include('business-token')
      end

      it 'does not flag reauthorization_required for manual whatsapp channel even when reauth required' do
        whatsapp_channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false,
                                                     validate_provider_config: false)
        whatsapp_channel.update!(provider_config: whatsapp_channel.provider_config.merge('source' => 'manual', 'app_secret' => 'secret'))
        whatsapp_inbox = create(:inbox, channel: whatsapp_channel, account: account)
        whatsapp_channel.prompt_reauthorization!

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['reauthorization_required']).to be(false)
      end

      it 'returns the inbox if assigned inbox is assigned as agent' do
        create(:inbox_member, user: agent, inbox: inbox)
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:id]).to eq(inbox.id)
        expect(data[:hmac_token]).to be_nil
      end

      it 'returns empty imap details in inbox when agent' do
        email_channel = create(:channel_email, account: account, imap_enabled: true, imap_login: 'test@test.com')
        email_inbox = create(:inbox, channel: email_channel, account: account)
        create(:inbox_member, user: agent, inbox: email_inbox)

        imap_connection = double
        allow(Mail).to receive(:connection).and_return(imap_connection)

        get "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:imap_enabled]).to be_nil
        expect(data[:imap_login]).to be_nil
      end

      it 'returns imap details in inbox when admin' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account, imap_enabled: true, imap_login: 'test@test.com')
        email_inbox = create(:inbox, channel: email_channel, account: account)
        create(:email_template, :layout, account: account, inbox: email_inbox, body: '<html>{{ content_for_layout }} Branded</html>')

        imap_connection = double
        allow(Mail).to receive(:connection).and_return(imap_connection)

        get "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:imap_enabled]).to be_truthy
        expect(data[:imap_login]).to eq('test@test.com')
        expect(data[:branded_email_layout]).to eq('<html>{{ content_for_layout }} Branded</html>')
      end

      it 'does not return saved branded email layout when feature is disabled' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        create(:email_template, :layout, account: account, inbox: email_inbox, body: '<html>{{ content_for_layout }} Branded</html>')

        get "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).not_to have_key('branded_email_layout')
      end

      it 'does not return branded email layout for an agent' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        create(:inbox_member, user: agent, inbox: email_inbox)
        create(:email_template, :layout, account: account, inbox: email_inbox, body: '<html>{{ content_for_layout }} Branded</html>')

        get "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:branded_email_layout]).to be_nil
      end

      context 'when it is a Twilio inbox' do
        let(:twilio_channel) { create(:channel_twilio_sms, account: account, account_sid: 'AC123', auth_token: 'secrettoken') }
        let(:twilio_inbox) { create(:inbox, channel: twilio_channel, account: account) }

        it 'returns auth_token and account_sid for admin' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{twilio_inbox.id}",
              headers: admin.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:success)
          data = JSON.parse(response.body, symbolize_names: true)
          expect(data[:auth_token]).to eq('secrettoken')
          expect(data[:account_sid]).to eq('AC123')
        end

        it "doesn't return auth_token and account_sid for agent" do
          create(:inbox_member, user: agent, inbox: twilio_inbox)
          get "/api/v1/accounts/#{account.id}/inboxes/#{twilio_inbox.id}",
              headers: agent.create_new_auth_token,
              as: :json
          expect(response).to have_http_status(:success)
          data = JSON.parse(response.body, symbolize_names: true)
          expect(data[:auth_token]).to be_nil
          expect(data[:account_sid]).to be_nil
        end
      end

      it 'fetch API inbox without hmac token when agent' do
        api_channel = create(:channel_api, account: account)
        api_inbox = create(:inbox, channel: api_channel, account: account)
        create(:inbox_member, user: agent, inbox: api_inbox)

        get "/api/v1/accounts/#{account.id}/inboxes/#{api_inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:hmac_token]).to be_nil
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
        inbox.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end

      it 'delete inbox avatar for administrator user' do
        perform_enqueued_jobs(only: DeleteObjectJob) do
          delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/avatar",
                 headers: admin.create_new_auth_token,
                 as: :json
        end

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
        expect(DeleteObjectJob).to receive(:perform_later).with(inbox, admin, anything).once

        perform_enqueued_jobs(only: DeleteObjectJob) do
          delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end

        json_response = response.parsed_body

        expect(response).to have_http_status(:success)
        expect(json_response['message']).to eq('Your inbox deletion request will be processed in some time.')
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
        expect(response).to conform_schema(200)
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
        token_service = instance_double(Sms::BandwidthTokenService, token: 'token')
        allow(Sms::BandwidthTokenService).to receive(:new).and_return(token_service)
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: { name: 'Sms Inbox',
                       channel: { type: 'sms', phone_number: '+123456789',
                                  provider_config: { account_id: '123', application_id: 'app', client_id: 'client', client_secret: 'secret' } } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Sms Inbox')
        expect(response.body).to include('+123456789')
      end

      context 'when creating a manual whatsapp cloud inbox' do
        let(:provider_config) do
          { api_key: 'test_key', phone_number_id: '123456', business_account_id: '654321', app_secret: 'test_app_secret' }
        end
        let(:whatsapp_params) do
          { name: 'WhatsApp Inbox',
            channel: { type: 'whatsapp', phone_number: '+15551234567', provider: 'whatsapp_cloud', provider_config: provider_config } }
        end
        let(:webhook_setup_service) { instance_double(Whatsapp::WebhookSetupService, perform: true) }

        before do
          stub_request(:get, %r{graph\.facebook\.com/v14\.0/654321/message_templates})
            .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
          stub_request(:get, %r{graph\.facebook\.com/v14\.0/654321/phone_numbers})
            .to_return(status: 200, body: { data: [{ id: '123456' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
          allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_setup_service)
          # The fork checks the app secret against the token with an appsecret_proof call.
          stub_request(:get, %r{graph\.facebook\.com/v\d+\.\d+/me})
            .to_return(status: 200, body: { id: '1' }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'creates the inbox with the app secret and conforms to the documented contract' do
          post "/api/v1/accounts/#{account.id}/inboxes",
               headers: admin.create_new_auth_token,
               params: whatsapp_params,
               as: :json

          expect(response).to have_http_status(:success)
          expect(response).to conform_schema(200)
          expect(Channel::Whatsapp.last.provider_config['app_secret']).to eq('test_app_secret')
        end

        it 'rejects a request without the app secret, which the documented contract also rejects' do
          whatsapp_params[:channel][:provider_config] = provider_config.except(:app_secret)

          post "/api/v1/accounts/#{account.id}/inboxes",
               headers: admin.create_new_auth_token,
               params: whatsapp_params,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).not_to conform_request_schema
        end
      end

      it 'creates the webwidget inbox that allow messages after conversation is resolved' do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
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
      let!(:portal) { create(:portal, account_id: account.id) }
      let(:valid_params) { { name: 'new test inbox', enable_auto_assignment: false, portal_id: portal.id } }

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
        expect(response).to conform_schema(200)
        expect(inbox.reload.enable_auto_assignment).to be_falsey
        expect(inbox.reload.portal_id).to eq(portal.id)
        expect(response.parsed_body['name']).to eq 'new test inbox'
      end

      it 'turns the reopen team setting on and off and exposes it' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token, params: { drop_assignee_outside_team_on_reopen: true }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['drop_assignee_outside_team_on_reopen']).to be(true)
        expect(inbox.reload.drop_assignee_outside_team_on_reopen).to be(true)

        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json
        expect(response.parsed_body['drop_assignee_outside_team_on_reopen']).to be(true)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token, params: { drop_assignee_outside_team_on_reopen: false }, as: :json

        expect(response.parsed_body['drop_assignee_outside_team_on_reopen']).to be(false)
        expect(inbox.reload.drop_assignee_outside_team_on_reopen).to be(false)
      end

      it 'refuses a reopen team setting that is not a boolean, without touching it' do
        inbox.update!(drop_assignee_outside_team_on_reopen: true)

        ['false', 0, '', nil, 'null', [false]].each do |value|
          patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
                headers: admin.create_new_auth_token, params: { drop_assignee_outside_team_on_reopen: value }, as: :json

          expect(response).to have_http_status(:unprocessable_entity), "accepted #{value.inspect}"
          expect(inbox.reload.drop_assignee_outside_team_on_reopen).to be(true)
        end
      end

      it 'turns assignment during business hours only on and off and exposes it' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token, params: { restrict_assignment_to_working_hours: true }, as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.reload.restrict_assignment_to_working_hours).to be(true)

        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json
        expect(response.parsed_body['restrict_assignment_to_working_hours']).to be(true)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token, params: { restrict_assignment_to_working_hours: false }, as: :json

        expect(response.parsed_body['restrict_assignment_to_working_hours']).to be(false)
        expect(inbox.reload.restrict_assignment_to_working_hours).to be(false)
      end

      it 'refuses a business hours assignment setting that is not a boolean' do
        inbox.update!(restrict_assignment_to_working_hours: true)

        ['false', '', nil].each do |value|
          patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
                headers: admin.create_new_auth_token, params: { restrict_assignment_to_working_hours: value }, as: :json

          expect(response).to have_http_status(:unprocessable_entity), "accepted #{value.inspect}"
          expect(inbox.reload.restrict_assignment_to_working_hours).to be(true)
        end
      end

      it 'sets who owns a reopened conversation and exposes it' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token, params: { reopen_owner: 'assignee_within_window', reopen_owner_window_hours: 6 }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include('reopen_owner' => 'assignee_within_window', 'reopen_owner_window_hours' => 6)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token, params: { reopen_owner: 'assignee' }, as: :json

        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json
        expect(response.parsed_body['reopen_owner']).to eq('assignee')
      end

      it 'defaults to handing a reopened conversation to the agent bot' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body).to include('reopen_owner' => 'agent_bot', 'reopen_owner_window_hours' => nil)
      end

      it 'refuses an invalid reopen owner or window, without touching it' do
        [
          { reopen_owner: 'assignee_within_window', reopen_owner_window_hours: 0 },
          { reopen_owner: 'assignee_within_window', reopen_owner_window_hours: -1 },
          { reopen_owner: 'assignee_within_window', reopen_owner_window_hours: 'abc' },
          { reopen_owner: 'assignee_within_window', reopen_owner_window_hours: '6' },
          { reopen_owner: 'assignee_within_window', reopen_owner_window_hours: Inbox::MAX_WINDOW_HOURS + 1 },
          { reopen_owner: 'assignee_within_window' },
          { reopen_owner: 'nobody' },
          { reopen_owner: 1 }
        ].each do |params|
          patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}", headers: admin.create_new_auth_token, params: params, as: :json

          expect(response).to have_http_status(:unprocessable_entity), "accepted #{params.inspect}"
          expect(inbox.reload.reopen_owner).to eq('agent_bot')
        end
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

      it 'updates whatsapp inbox when administrator' do
        stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook').to_return(status: 200, body: '', headers: {})
        stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates').to_return(status: 200, body: '', headers: {})
        whatsapp_channel = create(:channel_whatsapp, account: account)
        whatsapp_inbox = create(:inbox, channel: whatsapp_channel, account: account)
        whatsapp_channel.prompt_reauthorization!

        expect(whatsapp_channel).to be_reauthorization_required

        patch "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { enable_auto_assignment: false, channel: { provider_config: { api_key: 'new_key' } } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(whatsapp_inbox.reload.enable_auto_assignment).to be_falsey
        expect(whatsapp_channel.reload.provider_config['api_key']).to eq('new_key')
        expect(whatsapp_channel.reload).not_to be_reauthorization_required
      end

      it 'adds an app secret to a manual whatsapp cloud inbox and conforms to the documented contract' do
        stub_request(:get, %r{graph\.facebook\.com/v14\.0/.*/message_templates})
          .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{graph\.facebook\.com/v14\.0/.*/phone_numbers})
          .to_return(status: 200, body: { data: [{ id: '123456' }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        # The fork checks the app secret against the token with an appsecret_proof call.
        stub_request(:get, %r{graph\.facebook\.com/v\d+\.\d+/me})
          .to_return(status: 200, body: { id: '1' }.to_json, headers: { 'Content-Type' => 'application/json' })
        # An existing manual inbox created before the app secret was required.
        whatsapp_channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false,
                                                    validate_provider_config: false,
                                                    provider_config: { 'api_key' => 'test_key', 'phone_number_id' => '123456',
                                                                       'source' => 'manual_setup_v2' })
        whatsapp_channel.save!(validate: false)
        whatsapp_inbox = create(:inbox, channel: whatsapp_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { channel: { provider_config: whatsapp_channel.provider_config.merge('app_secret' => 'test_app_secret') } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(whatsapp_channel.reload.provider_config['app_secret']).to eq('test_app_secret')
      end

      it 'updates twitter inbox when administrator' do
        twitter_channel = create(:channel_twitter_profile, account: account, tweets_enabled: true)
        twitter_inbox = create(:inbox, channel: twitter_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{twitter_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { channel: { tweets_enabled: false } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(twitter_channel.reload.tweets_enabled).to be(false)
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

      it 'updates branded email layout for email inbox when feature is enabled' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        layout = '<html><body><header>Brand</header>{{ content_for_layout }}</body></html>'

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: layout },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_inbox.reload.branded_email_layout).to eq(layout)
        expect(response.parsed_body['branded_email_layout']).to eq(layout)
      end

      it 'rejects branded email layouts larger than 256 KiB' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        slot = '{{ content_for_layout }}'
        large_layout = "#{'a' * (EmailTemplate::MAX_BODY_LENGTH - slot.length + 1)}#{slot}"

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: large_layout },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('is too long (maximum is 262144 characters)')
      end

      it 'rolls back branded email layout when inbox update fails' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { name: '', branded_email_layout: '<html>{{ content_for_layout }} Branded</html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(email_inbox.reload.branded_email_layout).to be_nil
      end

      it 'clears branded email layout when blank value is passed' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        create(:email_template, :layout, account: account, inbox: email_inbox)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '' },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_inbox.reload.branded_email_layout).to be_nil
      end

      it 'clears branded email layout when null string value is passed' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)
        create(:email_template, :layout, account: account, inbox: email_inbox)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: 'null' },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_inbox.reload.branded_email_layout).to be_nil
      end

      it 'rejects branded email layout when feature is disabled' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '<html>{{ content_for_layout }}</html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Branded email templates feature is not enabled')
        expect(email_inbox.reload.branded_email_layout).to be_nil
      end

      it 'ignores blank branded email layout when feature is disabled' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { name: 'Renamed Email Inbox', branded_email_layout: nil },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_inbox.reload.name).to eq('Renamed Email Inbox')
        expect(email_inbox.branded_email_layout).to be_nil
      end

      it 'rejects branded email layout for non-email inboxes' do
        account.enable_features!(:branded_email_templates)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '<html>{{ content_for_layout }}</html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Branded email layout is only supported for email inboxes')
      end

      it 'ignores blank branded email layout for non-email inboxes' do
        account.enable_features!(:branded_email_templates)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              params: { name: 'Renamed Inbox', branded_email_layout: '' },
              as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.reload.name).to eq('Renamed Inbox')
      end

      it 'rejects branded email layout without content slot' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '<html>No slot</html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('must include {{ content_for_layout }}')
      end

      it 'rejects branded email layout with invalid liquid syntax' do
        account.enable_features!(:branded_email_templates)
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '<html>{{ content_for_layout }} {{ broken </html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('has invalid Liquid syntax')
      end

      it 'updates twilio sms inbox when administrator' do
        twilio_sms_channel = create(:channel_twilio_sms, account: account)
        twilio_sms_inbox = create(:inbox, channel: twilio_sms_channel, account: account)
        expect(twilio_sms_inbox.reload.channel.account_sid).not_to eq('account_sid')
        expect(twilio_sms_inbox.reload.channel.auth_token).not_to eq('new_auth_token')

        patch "/api/v1/accounts/#{account.id}/inboxes/#{twilio_sms_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { channel: { account_sid: 'account_sid', auth_token: 'new_auth_token' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(twilio_sms_inbox.reload.channel.account_sid).to eq('account_sid')
        expect(twilio_sms_inbox.reload.channel.auth_token).to eq('new_auth_token')
      end

      it 'updates bandwidth sms callback authentication when administrator' do
        sms_inbox = create(:channel_sms, account: account).inbox

        patch "/api/v1/accounts/#{account.id}/inboxes/#{sms_inbox.id}",
              headers: admin.create_new_auth_token,
              params: { channel: { callback_auth_enforced: false } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(sms_inbox.channel.reload.callback_auth_enforced).to be(false)
        expect(response.parsed_body['callback_auth_password']).to eq(sms_inbox.channel.secret)
      end

      it 'resets the bandwidth sms callback password when administrator' do
        sms_inbox = create(:channel_sms, account: account).inbox
        old_secret = sms_inbox.channel.secret

        post "/api/v1/accounts/#{account.id}/inboxes/#{sms_inbox.id}/reset_secret",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(sms_inbox.channel.reload.secret).not_to eq(old_secret)
        expect(response.parsed_body['callback_auth_password']).to eq(sms_inbox.channel.secret)
      end

      it 'updates email inbox with imap when administrator' do
        email_channel = create(:channel_email, account: account)
        email_inbox = create(:inbox, channel: email_channel, account: account)

        imap_connection = instance_double(Net::IMAP, disconnected?: false)
        allow(Net::IMAP).to receive(:new).and_return(imap_connection)
        allow(imap_connection).to receive(:login)
        allow(imap_connection).to receive(:disconnect)

        patch "/api/v1/accounts/#{account.id}/inboxes/#{email_inbox.id}",
              headers: admin.create_new_auth_token,
              params: {
                channel: {
                  imap_enabled: true,
                  imap_address: 'imap.gmail.com',
                  imap_port: 993,
                  imap_login: 'imaptest@gmail.com',
                  imap_authentication: 'login'
                }
              },
              as: :json

        expect(response).to have_http_status(:success)
        expect(email_channel.reload.imap_enabled).to be true
        expect(email_channel.reload.imap_address).to eq('imap.gmail.com')
        expect(email_channel.reload.imap_port).to eq(993)
        expect(email_channel.reload.imap_authentication).to eq('login')
      end

      it 'updates avatar when administrator' do
        # no avatar before upload
        expect(inbox.avatar.attached?).to be(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: valid_params.merge(avatar: file),
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        inbox.reload
        expect(inbox.avatar.attached?).to be(true)
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
        allow(smtp_connection).to receive(:open_timeout=).and_return(10)
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
        allow(smtp_connection).to receive(:open_timeout=).and_return(10)
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
        allow(smtp_connection).to receive(:open_timeout=).and_return(10)
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

    context 'when handling CSAT configuration' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:inbox) { create(:inbox, account: account) }
      let(:csat_config) do
        {
          'display_type' => 'emoji',
          'message' => 'How would you rate your experience?',
          'survey_rules' => {
            'operator' => 'contains',
            'values' => %w[support help]
          }
        }
      end

      it 'successfully updates the inbox with CSAT configuration' do
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: {
                csat_survey_enabled: true,
                csat_config: csat_config
              },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
      end

      context 'when CSAT is configured' do
        before do
          patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
                params: {
                  csat_survey_enabled: true,
                  csat_config: csat_config
                },
                headers: admin.create_new_auth_token,
                as: :json
        end

        it 'returns configured CSAT settings in inbox details' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['csat_survey_enabled']).to be true

          saved_config = json_response['csat_config']
          expect(saved_config).to be_present
          expect(saved_config['display_type']).to eq('emoji')
        end

        it 'returns configured CSAT message' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              as: :json

          json_response = response.parsed_body
          saved_config = json_response['csat_config']
          expect(saved_config['message']).to eq('How would you rate your experience?')
        end

        it 'returns configured CSAT survey rules' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              headers: admin.create_new_auth_token,
              as: :json

          json_response = response.parsed_body
          saved_config = json_response['csat_config']
          expect(saved_config['survey_rules']['operator']).to eq('contains')
          expect(saved_config['survey_rules']['values']).to match_array(%w[support help])
        end

        it 'includes CSAT configuration in inbox list' do
          get "/api/v1/accounts/#{account.id}/inboxes",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          inbox_list = response.parsed_body
          found_inbox = inbox_list['payload'].find { |i| i['id'] == inbox.id }

          expect(found_inbox['csat_survey_enabled']).to be true
          expect(found_inbox['csat_config']).to be_present
          expect(found_inbox['csat_config']['display_type']).to eq('emoji')
        end
      end

      it 'successfully updates inbox with template configuration' do
        csat_config_with_template = csat_config.merge({
                                                        'template' => {
                                                          'name' => 'custom_survey_template',
                                                          'template_id' => '123456789',
                                                          'language' => 'en',
                                                          'created_at' => Time.current.iso8601
                                                        }
                                                      })

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: {
                csat_survey_enabled: true,
                csat_config: csat_config_with_template
              },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        inbox.reload
        template_config = inbox.csat_config['template']
        expect(template_config).to be_present
        expect(template_config['name']).to eq('custom_survey_template')
        expect(template_config['template_id']).to eq('123456789')
        expect(template_config['language']).to eq('en')
      end

      it 'returns template configuration in inbox details' do
        csat_config_with_template = csat_config.merge({
                                                        'template' => {
                                                          'name' => 'custom_survey_template',
                                                          'template_id' => '123456789',
                                                          'language' => 'en',
                                                          'created_at' => Time.current.iso8601
                                                        }
                                                      })

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: {
                csat_survey_enabled: true,
                csat_config: csat_config_with_template
              },
              headers: admin.create_new_auth_token,
              as: :json

        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        template_config = json_response['csat_config']['template']

        expect(template_config).to be_present
        expect(template_config['name']).to eq('custom_survey_template')
        expect(template_config['template_id']).to eq('123456789')
        expect(template_config['language']).to eq('en')
        expect(template_config['created_at']).to be_present
      end

      it 'removes template configuration when not provided in update' do
        # First set up template configuration
        csat_config_with_template = csat_config.merge({
                                                        'template' => {
                                                          'name' => 'custom_survey_template',
                                                          'template_id' => '123456789'
                                                        }
                                                      })

        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: {
                csat_survey_enabled: true,
                csat_config: csat_config_with_template
              },
              headers: admin.create_new_auth_token,
              as: :json

        # Then update without template
        patch "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}",
              params: {
                csat_survey_enabled: true,
                csat_config: csat_config.merge({ 'message' => 'Updated message' })
              },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        inbox.reload
        config = inbox.csat_config
        expect(config['message']).to eq('Updated message')
        expect(config['template']).to be_nil # Template should be removed when not provided
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
        expect(inbox_data[:agent_bot].blank?).to be(true)
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

      it 'does not allow binding an agent bot from another account' do
        other_account = create(:account)
        foreign_bot = create(:agent_bot, account: other_account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/set_agent_bot",
             headers: admin.create_new_auth_token,
             params: { agent_bot: foreign_bot.id },
             as: :json

        expect(response).to have_http_status(:not_found)
        expect(inbox.reload.agent_bot).to be_nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/:id/message_templates' do
    let(:last_sync_attempt_at) { 1.hour.ago.change(usec: 0) }
    let(:message_templates) do
      [
        { 'name' => 'shipping_update', 'language' => 'en_US' },
        { 'name' => 'shipping_update', 'language' => 'es' },
        { 'name' => 'account_update', 'language' => 'en_US' }
      ]
    end
    let(:whatsapp_channel) do
      create(
        :channel_whatsapp,
        account: account,
        message_templates: message_templates,
        message_templates_last_updated: last_sync_attempt_at,
        sync_templates: false,
        validate_provider_config: false
      )
    end
    let(:whatsapp_inbox) { whatsapp_channel.inbox }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/message_templates"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized when the agent is not assigned to the inbox' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/message_templates",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns the templates when the agent is assigned to the inbox' do
        create(:inbox_member, user: agent, inbox: whatsapp_inbox)

        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/message_templates",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to eq(message_templates)
        expect(Time.zone.parse(response.parsed_body.dig('meta', 'last_sync_attempt_at'))).to eq(last_sync_attempt_at)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'filters templates by exact name' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/message_templates",
            headers: admin.create_new_auth_token,
            params: { name: 'shipping_update' },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to eq(message_templates.first(2))
      end

      it 'returns an empty payload when the template name does not match' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/message_templates",
            headers: admin.create_new_auth_token,
            params: { name: 'missing_template' },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to eq([])
      end

      it 'returns unprocessable entity for a non-WhatsApp inbox' do
        inbox = create(:inbox, account: account)

        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/message_templates",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Message templates are only available for WhatsApp channels')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/:id/sync_templates' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    end
    let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
    let(:non_whatsapp_inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/sync_templates"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized for agent' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/sync_templates",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      context 'with WhatsApp inbox' do
        it 'successfully initiates template sync' do
          expect(Channels::Whatsapp::TemplatesSyncJob).to receive(:perform_later).with(whatsapp_channel)

          post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/sync_templates",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['message']).to eq('Template sync initiated successfully')
        end

        it 'handles job errors gracefully' do
          allow(Channels::Whatsapp::TemplatesSyncJob).to receive(:perform_later).and_raise(StandardError, 'Job failed')

          post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/sync_templates",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('Job failed')
        end
      end

      context 'with non-WhatsApp inbox' do
        it 'returns unprocessable entity error' do
          post "/api/v1/accounts/#{account.id}/inboxes/#{non_whatsapp_inbox.id}/sync_templates",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('Template sync is only available for WhatsApp channels')
        end
      end

      context 'with non-existent inbox' do
        it 'returns not found error' do
          post "/api/v1/accounts/#{account.id}/inboxes/999999/sync_templates",
               headers: admin.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/health' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    end
    let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
    let(:non_whatsapp_inbox) { create(:inbox, account: account) }
    let(:health_service) { instance_double(Whatsapp::HealthService) }
    let(:health_data) do
      {
        id: 'phone123',
        display_phone_number: '+1234567890',
        verified_name: 'Test Business',
        name_status: 'APPROVED',
        quality_rating: 'GREEN',
        messaging_limit_tier: 'TIER_1000',
        account_mode: 'LIVE',
        status: 'CONNECTED',
        business_account_id: 'waba123',
        business_account_name: 'Test WABA',
        business_portfolio_id: 'business123',
        business_portfolio_name: 'Test Business Portfolio'
      }
    end

    before do
      allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
      allow(health_service).to receive(:sync_health_status!).and_return(health_data)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      context 'with WhatsApp inbox' do
        it 'returns health data for administrator' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response).to include(
            'id' => 'phone123',
            'display_phone_number' => '+1234567890',
            'verified_name' => 'Test Business',
            'name_status' => 'APPROVED',
            'quality_rating' => 'GREEN',
            'messaging_limit_tier' => 'TIER_1000',
            'account_mode' => 'LIVE',
            'status' => 'CONNECTED',
            'business_account_id' => 'waba123',
            'business_account_name' => 'Test WABA',
            'business_portfolio_id' => 'business123',
            'business_portfolio_name' => 'Test Business Portfolio'
          )
        end

        it 'returns health data for agent with inbox access' do
          create(:inbox_member, user: agent, inbox: whatsapp_inbox)

          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['display_phone_number']).to eq('+1234567890')
        end

        it 'returns unauthorized for agent without inbox access' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unauthorized)
        end

        it 'calls the health service with correct channel' do
          expect(Whatsapp::HealthService).to receive(:new).with(whatsapp_channel).and_return(health_service)
          expect(health_service).to receive(:sync_health_status!).with(include_business_profile: true)

          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
        end

        it 'handles service errors gracefully' do
          allow(health_service).to receive(:sync_health_status!).and_raise(StandardError, 'API Error')

          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['error']).to include('API Error')
        end

        it 'classifies Meta authorization failures for the recovery UI' do
          error = Whatsapp::HealthService::ApiError.new(
            message: 'The access token cannot authorize this request.',
            http_status: 400,
            code: 190,
            subcode: 464
          )
          allow(health_service).to receive(:sync_health_status!).and_raise(error)

          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq(
            'type' => 'authorization',
            'message' => 'The access token cannot authorize this request.',
            'http_status' => 400,
            'code' => 190,
            'subcode' => 464
          )
        end
      end

      context 'with non-WhatsApp inbox' do
        it 'returns bad request error for administrator' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{non_whatsapp_inbox.id}/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('Health data only available for WhatsApp Cloud API and Twilio channels')
        end

        it 'returns bad request error for agent' do
          create(:inbox_member, user: agent, inbox: non_whatsapp_inbox)

          get "/api/v1/accounts/#{account.id}/inboxes/#{non_whatsapp_inbox.id}/health",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('Health data only available for WhatsApp Cloud API and Twilio channels')
        end
      end

      context 'with WhatsApp non-cloud inbox' do
        let(:whatsapp_default_channel) do
          create(:channel_whatsapp, account: account, provider: 'default', sync_templates: false, validate_provider_config: false)
        end
        let(:whatsapp_default_inbox) { create(:inbox, account: account, channel: whatsapp_default_channel) }

        it 'returns bad request error for non-cloud provider' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_default_inbox.id}/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = response.parsed_body
          expect(json_response['error']).to eq('Health data only available for WhatsApp Cloud API and Twilio channels')
        end
      end

      context 'with non-existent inbox' do
        it 'returns not found error' do
          get "/api/v1/accounts/#{account.id}/inboxes/999999/health",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # The button on the inbox health screen. Meta refuses the per-number override for a whole class
  # of accounts, and since that refusal stopped taking the channel down (#568) the answer here was
  # "registered successfully" either way, which is the only thing the operator sees at the moment
  # they press it.
  # Meta answers three levels of webhook routing and delivery follows the most specific one that
  # exists, so the same green "configured" URL means two different things: the inbox owns its
  # routing, or it is riding on the app's own callback and stops the day that URL changes.
  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/health routing level' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    end
    let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
    let(:expected_url) { 'https://chat.example.com/webhooks/whatsapp/+123' }
    let(:health_service) { instance_double(Whatsapp::HealthService) }

    # The outer keys are the service's own symbols; the ones inside come from Meta's JSON.
    def stub_health(configuration)
      allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
      allow(health_service).to receive(:sync_health_status!).and_return(
        { id: 'phone123', webhook_configuration: configuration, expected_webhook_url: expected_url }
      )
    end

    def routing_answer
      get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/health",
          headers: admin.create_new_auth_token, as: :json
      response.parsed_body['routed_by_app_callback_only']
    end

    it 'is false when this number has an override of its own' do
      stub_health({ 'phone_number' => expected_url, 'application' => 'https://elsewhere.example.com/hook' })

      expect(routing_answer).to be(false)
    end

    it 'is false when the business account has one' do
      stub_health({ 'whatsapp_business_account' => expected_url, 'application' => 'https://elsewhere.example.com/hook' })

      expect(routing_answer).to be(false)
    end

    # Delivery follows the most specific override that exists, wherever it points: a number sent
    # to the wrong place is misrouted, not riding on the app callback, and the card already says
    # so with its own URL mismatch warning.
    it 'is false when the override exists but points somewhere else' do
      stub_health({ 'phone_number' => 'https://elsewhere.example.com/hook', 'application' => expected_url })

      expect(routing_answer).to be(false)
    end

    it 'is true when only the app callback is pointed here' do
      stub_health({ 'application' => expected_url })

      expect(routing_answer).to be(true)
    end

    # Not knowing is not a warning: Meta answering nothing about the configuration says nothing
    # about where this number is routed.
    it 'is false when Meta did not answer the configuration' do
      stub_health(nil)

      expect(routing_answer).to be(false)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/{inbox.id}/register_webhook' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    end
    let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
    let(:phone_number_id) { whatsapp_channel.provider_config['phone_number_id'] }
    let(:waba_id) { whatsapp_channel.provider_config['business_account_id'] }
    let(:api_version) { 'v22.0' }
    let(:subscription) do
      stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
        .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    # The endpoint reads the routing back after the attempt, so every example here answers that read
    # too. One stub covers both GETs because the factory gives the phone number and the business
    # account the same id, and each formatter reads its own keys out of the body.
    let(:health_api_version) { 'v24.0' }
    let(:elsewhere_url) { 'https://elsewhere.example.com/webhooks/whatsapp/+123' }

    def stub_health_read(phone_number_override)
      stub_request(:get, %r{graph\.facebook\.com/#{health_api_version}/#{phone_number_id}})
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: {
          id: phone_number_id,
          display_phone_number: '+1 234 567 8911',
          webhook_configuration: { phone_number: phone_number_override }.compact,
          name: 'WABA',
          owner_business_info: { id: 'biz', name: 'Portfolio' }
        }.to_json)
    end

    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return(api_version)
      subscription
      stub_health_read(elsewhere_url)
    end

    context 'when Meta accepts both calls' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'says the routing was applied' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/register_webhook",
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include('message' => 'Webhook registered successfully', 'callback_override_applied' => true)
      end
    end

    # The refusal this endpoint has to describe: the WABA subscription lands, so Meta delivers,
    # and the number is not pointed at this installation.
    context 'when Meta refuses the per-number override' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json)
      end

      it 'still succeeds, and says the routing was not applied' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/register_webhook",
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include('message' => 'Webhook registered successfully', 'callback_override_applied' => false)
        expect(subscription).to have_been_requested
      end

      it 'leaves the channel authorized, which is what #568 fixed' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/register_webhook",
             headers: admin.create_new_auth_token, as: :json

        expect(whatsapp_channel.reload.reauthorization_required?).to be(false)
      end
    end

    context 'when the subscription Meta needs fails' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .to_return(status: 400, body: { error: { message: 'App subscription to WABA failed' } }.to_json)
      end

      it 'answers the failure instead of a partial success' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/register_webhook",
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('Webhook setup failed')
        expect(response.parsed_body).not_to have_key('callback_override_applied')
      end
    end

    # `callback_override_applied` answers one write, and a refusal, a 500 and a connection that
    # closes with nothing to read all reach it as the same `false`. Where delivery goes afterwards
    # is a different question, and the only authority on it is Meta, read back after the attempt.
    context 'when the answer has to say where delivery goes' do
      let(:expected_url) { "#{ENV.fetch('FRONTEND_URL', 'http://www.chatwoot.test')}/webhooks/whatsapp/#{whatsapp_channel.phone_number}" }

      def register
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/register_webhook",
             headers: admin.create_new_auth_token, as: :json
        response.parsed_body
      end

      it 'reads the routing back when Meta refused the write, and answers what it found' do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json)
        stub_health_read(elsewhere_url)

        body = register

        expect(response).to have_http_status(:success)
        expect(body['callback_override_applied']).to be(false)
        expect(body['routing_read_back']).to be(true)
        expect(body.dig('health', 'webhook_configuration', 'phone_number')).to eq(elsewhere_url)
      end

      # The case this endpoint could not describe: Meta stored the override and then answered 500.
      # The write is not confirmed and the routing did change, so an answer derived from the write
      # alone contradicts the card that is rendered from the read.
      it 'answers the routing the write actually left, even though the write was not confirmed' do
        # The fake Meta stores the override and only then fails, and the read answers what is
        # stored at the moment it is asked. So a read taken before the write would answer the old
        # URL, and this example is what pins the order rather than only the value.
        stored = elsewhere_url
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return do
            stored = expected_url
            { status: 500, body: { error: { message: 'An unexpected error has occurred.', code: 1 } }.to_json }
          end
        stub_request(:get, %r{graph\.facebook\.com/#{health_api_version}/#{phone_number_id}})
          .to_return do
            { status: 200, headers: { 'Content-Type' => 'application/json' },
              body: { id: phone_number_id, webhook_configuration: { phone_number: stored } }.to_json }
          end

        body = register

        expect(body['callback_override_applied']).to be(false)
        expect(body['routing_read_back']).to be(true)
        expect(body.dig('health', 'webhook_configuration', 'phone_number')).to eq(expected_url)
        expect(body.dig('health', 'routed_by_app_callback_only')).to be(false)
      end

      # The read is the addition, so it is the thing that must not cost anything: a write that
      # landed cannot be reported as a failure because the read after it did not come back.
      it 'says the routing is unknown when it could not be read back, and still answers 2xx' do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, %r{graph\.facebook\.com/#{health_api_version}/}).to_return(status: 500, body: '{}')

        body = register

        expect(response).to have_http_status(:success)
        expect(body['callback_override_applied']).to be(true)
        expect(body['routing_read_back']).to be(false)
        expect(body).not_to have_key('health')
      end

      # Two arrangements that differ only in what Meta did with the write, and a consumer that is
      # not the dashboard has to be able to tell them apart.
      it 'answers differently for a refused write and one that landed before the error' do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json)
        stub_health_read(elsewhere_url)
        refused = register

        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .to_return(status: 500, body: { error: { message: 'An unexpected error has occurred.', code: 1 } }.to_json)
        stub_health_read(expected_url)
        landed = register

        expect(refused['callback_override_applied']).to eq(landed['callback_override_applied'])
        expect(refused.dig('health', 'webhook_configuration', 'phone_number'))
          .not_to eq(landed.dig('health', 'webhook_configuration', 'phone_number'))
      end
    end

    context 'when the user is not an administrator' do
      it 'refuses' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/register_webhook",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/inboxes/:id/setup_channel_provider' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false) }
    let(:inbox) { channel.inbox }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/setup_channel_provider"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns unprocessable entity when channel does not support setup' do
        inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/setup_channel_provider",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Channel does not support setup')
      end

      it 'calls setup_channel_provider when supported and returns ok' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, setup_channel_provider: true)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/setup_channel_provider",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
      end

      # The pairing UI calls this and shows whatever comes back, so an error the session
      # layer raises on purpose has to arrive as a sentence and a status the dashboard can
      # act on. A wrong Uazapi token used to escape as a 500 and read as a blank wall.
      it 'answers a session error with its own status instead of a 500' do
        session_channel = create(:channel_whatsapp, account: account, provider: 'uazapi',
                                                    validate_provider_config: false, sync_templates: false)
        allow_any_instance_of(Whatsapp::Session::Facade) # rubocop:disable RSpec/AnyInstance
          .to receive(:setup_channel_provider)
          .and_raise(Whatsapp::Session::Errors::Unauthorized, 'the instance refused the token')

        post "/api/v1/accounts/#{account.id}/inboxes/#{session_channel.inbox.id}/setup_channel_provider",
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include('error' => 'the instance refused the token', 'code' => 'unauthorized')
      end

      it 'answers a provider that is down with a 503, which is worth retrying' do
        session_channel = create(:channel_whatsapp, account: account, provider: 'uazapi',
                                                    validate_provider_config: false, sync_templates: false)
        allow_any_instance_of(Whatsapp::Session::Facade) # rubocop:disable RSpec/AnyInstance
          .to receive(:setup_channel_provider)
          .and_raise(Whatsapp::Session::Errors::ProviderUnavailable, 'the instance did not answer')

        post "/api/v1/accounts/#{account.id}/inboxes/#{session_channel.inbox.id}/setup_channel_provider",
             headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:service_unavailable)
      end

      it 'allows agents to setup channel provider for assigned inboxes' do
        create(:inbox_member, user: agent, inbox: inbox)
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, setup_channel_provider: true)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/setup_channel_provider",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'returns unauthorized for agents not assigned to the inbox' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/setup_channel_provider",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/inboxes/:id/request_pairing_code' do
    let(:session_channel) do
      create(:channel_whatsapp, account: account, provider: 'uazapi', validate_provider_config: false, sync_templates: false)
    end
    let(:session_inbox) { session_channel.inbox }

    it 'returns unauthorized when unauthenticated' do
      post "/api/v1/accounts/#{account.id}/inboxes/#{session_inbox.id}/request_pairing_code"

      expect(response).to have_http_status(:unauthorized)
    end

    # Same privilege as scanning a QR for the inbox, and granted the same way: both link
    # a WhatsApp account to an inbox this agent is already assigned to.
    it 'lets an assigned agent ask for one' do
      create(:inbox_member, user: agent, inbox: session_inbox)
      allow_any_instance_of(Whatsapp::Session::Facade).to receive(:request_pairing_code) # rubocop:disable RSpec/AnyInstance

      post "/api/v1/accounts/#{account.id}/inboxes/#{session_inbox.id}/request_pairing_code",
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'returns unauthorized for an agent who is not on the inbox' do
      post "/api/v1/accounts/#{account.id}/inboxes/#{session_inbox.id}/request_pairing_code",
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    # The route is on every inbox, and only the session family can answer it. A provider
    # that cannot pair by code has to say so as a sentence, not as a 500.
    it 'refuses a provider that does not pair by code' do
      legacy = create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false)

      post "/api/v1/accounts/#{account.id}/inboxes/#{legacy.inbox.id}/request_pairing_code",
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['code']).to eq('unsupported')
    end

    it 'refuses a channel that has no pairing at all' do
      post "/api/v1/accounts/#{account.id}/inboxes/#{create(:inbox, account: account).id}/request_pairing_code",
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'answers a provider that is down with a 503, which is worth retrying' do
      allow_any_instance_of(Whatsapp::Session::Facade) # rubocop:disable RSpec/AnyInstance
        .to receive(:request_pairing_code)
        .and_raise(Whatsapp::Session::Errors::ProviderUnavailable, 'the instance did not answer')

      post "/api/v1/accounts/#{account.id}/inboxes/#{session_inbox.id}/request_pairing_code",
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:service_unavailable)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/inboxes/:id/import_whatsapp_session' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false) }
    let(:inbox) { channel.inbox }
    let(:session_payload) do
      {
        noiseCandidates: [{ private: 'np0', public: 'nb0' }],
        identityKey: { private: 'ip', public: 'ib' },
        registrationId: 42,
        advSecretKey: 'adv',
        account: { details: 'd', accountSignatureKey: 'ask', accountSignature: 'as', deviceSignature: 'ds' },
        id: '551101234567:12@s.whatsapp.net'
      }
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/import_whatsapp_session"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns unprocessable entity for a non-baileys channel' do
        other = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{other.id}/import_whatsapp_session",
             params: { session: session_payload },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable entity for a whatsapp channel using a non-baileys provider' do
        cloud_channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                                  sync_templates: false, validate_provider_config: false)

        post "/api/v1/accounts/#{account.id}/inboxes/#{cloud_channel.inbox.id}/import_whatsapp_session",
             params: { session: session_payload },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable entity when the session payload is missing' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)
        allow(service_double).to receive(:import_session)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/import_whatsapp_session",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(service_double).not_to have_received(:import_session)
      end

      it 'imports the session and returns ok' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)
        allow(service_double).to receive(:import_session).and_return(true)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/import_whatsapp_session",
             params: { session: session_payload, candidate_index: 1 },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(service_double).to have_received(:import_session).with(session: kind_of(Hash), candidate_index: 1)
      end

      it 'returns service unavailable when the provider is unavailable' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)
        allow(service_double).to receive(:import_session)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/import_whatsapp_session",
             params: { session: session_payload },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:service_unavailable)
      end

      it 'allows agents assigned to the inbox' do
        create(:inbox_member, user: agent, inbox: inbox)
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, import_session: true)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/import_whatsapp_session",
             params: { session: session_payload },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'returns unauthorized for agents not assigned to the inbox' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/import_whatsapp_session",
             params: { session: session_payload },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/inboxes/:id/disconnect_channel_provider' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false) }
    let(:inbox) { channel.inbox }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/disconnect_channel_provider"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns unprocessable entity when channel does not support disconnect' do
        inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/disconnect_channel_provider",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Channel does not support disconnect')
      end

      it 'calls disconnect_channel_provider when supported and returns ok' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, disconnect_channel_provider: true)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/disconnect_channel_provider",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(channel.reload.provider_connection).to eq('connection' => 'close')
      end

      # Disconnect is the documented recovery for a send stall, and re-pairing is the only
      # thing that replaces the wedged socket. Recording 'close' on a disconnect the
      # provider refused would clear the stall warning without replacing anything: the
      # operator is told it worked, the banner disappears, and the inbox is still mute
      # with no signal left to say so.
      it 'leaves the connection untouched when the provider refuses to end the session' do
        channel.update_provider_connection!(
          connection: 'open',
          send_stall: { 'consecutive_timeouts' => 3, 'action' => 'suppressed' }
        )
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService)
        allow(service_double).to receive(:disconnect_channel_provider)
          .and_raise(Whatsapp::Session::Errors::ProviderUnavailable.new('The provider did not end the session (HTTP 500)'))
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/disconnect_channel_provider",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:service_unavailable)
        expect(channel.reload.provider_connection).to include(
          'connection' => 'open',
          'send_stall' => { 'consecutive_timeouts' => 3, 'action' => 'suppressed' }
        )
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/inboxes/:id/convert_provider' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:inbox) { channel.inbox }
    let(:new_cloud_config) do
      { api_key: 'new_cloud_key', phone_number_id: 'new_phone_id', business_account_id: 'new_waba_id', app_secret: 'new_secret' }
    end

    before do
      stub_request(:delete, "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}")
        .to_return(status: 200)
      stub_request(:get, %r{graph\.facebook\.com/v\d+\.\d+/.*/message_templates.*})
        .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r{graph\.facebook\.com/v\d+\.\d+/.*/phone_numbers.*})
        .to_return(status: 200, body: { data: [{ id: 'new_phone_id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r{graph\.facebook\.com/v\d+\.\d+/me\?}).to_return(status: 200, body: { id: '1' }.to_json)
      webhook_setup_service = instance_double(Whatsapp::WebhookSetupService, perform: nil)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_setup_service)
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             params: { provider: 'whatsapp_cloud', provider_config: new_cloud_config }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: agent.create_new_auth_token,
             params: { provider: 'whatsapp_cloud', provider_config: new_cloud_config },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized even when the agent is assigned to the inbox' do
        create(:inbox_member, user: agent, inbox: inbox)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: agent.create_new_auth_token,
             params: { provider: 'whatsapp_cloud', provider_config: new_cloud_config },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an administrator' do
      it 'converts the channel to the new provider' do # rubocop:disable RSpec/MultipleExpectations
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: admin.create_new_auth_token,
             params: { provider: 'whatsapp_cloud', provider_config: new_cloud_config },
             as: :json

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['provider']).to eq('whatsapp_cloud')
        expect(body['provider_config']).to include(
          'api_key' => 'new_cloud_key',
          'phone_number_id' => 'new_phone_id',
          'business_account_id' => 'new_waba_id'
        )
        expect(body['provider_config']).not_to have_key('provider_url')
        channel.reload
        expect(channel.provider).to eq('whatsapp_cloud')
        expect(channel.provider_config).to include(
          'api_key' => 'new_cloud_key',
          'phone_number_id' => 'new_phone_id',
          'business_account_id' => 'new_waba_id'
        )
        expect(channel.provider_config).not_to have_key('provider_url')
        expect(channel.provider_connection).to be_blank
        expect(channel.message_templates).to be_blank
      end

      it 'returns 422 when the channel does not support conversion' do
        other_inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}/convert_provider",
             headers: admin.create_new_auth_token,
             params: { provider: 'whatsapp_cloud', provider_config: new_cloud_config },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to match(/does not support provider conversion/i)
      end

      it 'returns 400 when the provider param is missing' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: admin.create_new_auth_token,
             params: { provider_config: new_cloud_config },
             as: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['message']).to match(/provider/i)
      end

      it 'returns 422 when the new provider config is invalid' do
        cloud_service = instance_double(Whatsapp::Providers::WhatsappCloudService, validate_provider_config?: false)
        allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(cloud_service)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: admin.create_new_auth_token,
             params: { provider: 'whatsapp_cloud', provider_config: { api_key: 'bad' } },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to match(/invalid credentials/i)
      end

      it 'returns 422 with a fallback message when conversion raises a generic error' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:convert_provider!).and_raise(StandardError, 'boom') # rubocop:disable RSpec/AnyInstance

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: admin.create_new_auth_token,
             params: { provider: 'whatsapp_cloud', provider_config: new_cloud_config },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to match(/provider conversion failed/i)
      end

      it 'returns 422 when converting to the same provider' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/convert_provider",
             headers: admin.create_new_auth_token,
             params: { provider: channel.provider, provider_config: {} },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to match(/must be different/i)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/inboxes/:id/on_whatsapp' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false) }
    let(:inbox) { channel.inbox }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/on_whatsapp"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns unprocessable entity when channel does not support on_whatsapp' do
        inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/on_whatsapp",
             headers: admin.create_new_auth_token,
             params: { phone_number: '+123456789' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Channel does not support whatsapp check')
      end

      it 'returns unprocessable entity when phone_number is not passed' do
        inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/on_whatsapp",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('param is missing or the value is empty or invalid: phone_number')
      end

      it 'calls on_whatsapp when supported and returns provider response' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService,
                                         on_whatsapp: { jid: '123456789@s.whatsapp.net', exists: true, lid: '123@lid' })
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/on_whatsapp",
             headers: admin.create_new_auth_token,
             params: { phone_number: '+123456789' },
             as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'passes an advisory lookup on to the provider' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, on_whatsapp: { 'exists' => false })
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/on_whatsapp",
             headers: admin.create_new_auth_token,
             params: { phone_number: '+123456789', advisory: true },
             as: :json

        expect(service_double).to have_received(:on_whatsapp).with('+123456789', deadline: :hint)
      end

      it 'calls on_whatsapp when supported and returns default response on no response from provider' do
        service_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, on_whatsapp: nil)
        allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
          .with(whatsapp_channel: channel)
          .and_return(service_double)

        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/on_whatsapp",
             headers: admin.create_new_auth_token,
             params: { phone_number: '+123456789' },
             as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Twilio inbox health' do
    let(:twilio_channel) { create(:channel_twilio_sms, :with_phone_number, account: account) }
    let(:twilio_inbox) { create(:inbox, account: account, channel: twilio_channel) }
    let(:health_service) { instance_double(Twilio::HealthService) }
    let(:health_data) do
      { status: 'misconfigured', webhooks: [{ name: 'messaging', configured: false }] }
    end

    let(:webhook_service) { instance_double(Twilio::WebhookSetupService, perform: true) }

    before do
      allow(Twilio::HealthService).to receive(:new).with(channel: twilio_channel).and_return(health_service)
      allow(health_service).to receive(:perform).and_return(health_data)
      allow(Twilio::WebhookSetupService).to receive(:new).with(channel: twilio_channel).and_return(webhook_service)
    end

    it 'returns the twilio webhook health' do
      get "/api/v1/accounts/#{account.id}/inboxes/#{twilio_inbox.id}/health",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('misconfigured')
    end

    it 'serializes the full health payload over http' do
      allow(Twilio::HealthService).to receive(:new).with(channel: twilio_channel).and_call_original
      twilio_client = instance_double(Twilio::REST::Client)
      number = instance_double(Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberInstance,
                               sid: 'PN123', phone_number: twilio_channel.phone_number, friendly_name: 'Support line',
                               capabilities: { 'voice' => false, 'sms' => true, 'mms' => true },
                               sms_url: 'https://elsewhere.example.com/hook', sms_method: 'POST', sms_application_sid: nil)
      allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_client).to receive(:incoming_phone_numbers).and_return(
        instance_double(Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberList, list: [number])
      )
      allow(twilio_client).to receive(:api).and_return(
        instance_double(Twilio::REST::Api,
                        accounts: instance_double(Twilio::REST::Api::V2010::AccountContext,
                                                  fetch: instance_double(Twilio::REST::Api::V2010::AccountInstance,
                                                                         sid: 'AC123', friendly_name: 'Acme Support',
                                                                         status: 'active', type: 'Trial')))
      )

      get "/api/v1/accounts/#{account.id}/inboxes/#{twilio_inbox.id}/health",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include(
        'status' => 'misconfigured',
        'voice_enabled' => false,
        'account' => { 'sid' => 'AC123', 'friendly_name' => 'Acme Support', 'status' => 'active', 'type' => 'Trial' }
      )
      expect(response.parsed_body['sender']).to include('type' => 'phone_number', 'label' => twilio_channel.phone_number)
      expect(response.parsed_body['webhooks'].first).to include('name' => 'messaging', 'configured' => false, 'reason' => 'url_mismatch')
    end

    it 'returns health data for a twilio whatsapp inbox' do
      whatsapp_medium_inbox = create(:inbox, account: account, channel: create(:channel_twilio_sms, :whatsapp, account: account))

      allow(Twilio::HealthService).to receive(:new).with(channel: whatsapp_medium_inbox.channel).and_return(health_service)

      get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_medium_inbox.id}/health",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
    end

    it 'registers the messaging webhook' do
      post "/api/v1/accounts/#{account.id}/inboxes/#{twilio_inbox.id}/register_webhook",
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(webhook_service).to have_received(:perform)
    end
  end
end
