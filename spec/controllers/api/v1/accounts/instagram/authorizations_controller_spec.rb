require 'rails_helper'

RSpec.describe 'Instagram Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/instagram/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/instagram/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      context 'when Unified Login is configured' do
        before do
          allow(Instagram::UnifiedLoginService).to receive(:credentials).and_return(client_id: 'meta_app', client_secret: 'meta_secret')
          allow(GlobalConfigService).to receive(:load).and_call_original
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('unified_login')
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_CONFIGURATION_ID', nil).and_return('config1')
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_ID', nil).and_return('meta_app')
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_UNIFIED_APP_SECRET', nil).and_return('meta_secret')
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_APP_SECRET', nil).and_return('state_secret')
        end

        it 'uses config_id and signs the login type and onboarding destination' do
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token,
                                                                         params: { return_to: 'onboarding' }, as: :json

          url = URI(response.parsed_body.fetch('url'))
          query = Rack::Utils.parse_query(url.query)
          expect(url.host).to eq('www.facebook.com')
          expect(query).to include('client_id' => 'meta_app', 'config_id' => 'config1', 'response_type' => 'code',
                                   'override_default_response_type' => 'true')
          expect(query).not_to have_key('scope')
          payload = JWT.decode(query.fetch('state'), 'state_secret', true, algorithm: 'HS256').first
          expect(payload).to include('sub' => account.id, 'configuration_id' => 'config1', 'return_to' => 'onboarding')
        end

        it 'rejects an incomplete configuration before redirecting to Meta' do
          allow(Instagram::UnifiedLoginService).to receive(:credentials)
            .and_raise(Instagram::UnifiedLoginService::Error, I18n.t('instagram.missing_credentials'))
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq(I18n.t('instagram.missing_credentials'))
        end

        it 'keeps an existing Instagram Login inbox on its original method and signs its inbox ID' do
          channel = create(:channel_instagram, account: account)
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token,
                                                                         params: { inbox_id: channel.inbox.id }, as: :json
          query = Rack::Utils.parse_query(URI(response.parsed_body.fetch('url')).query)
          payload = JWT.decode(query.fetch('state'), 'state_secret', true, algorithm: 'HS256').first
          expect(payload).to include('sub' => account.id, 'inbox_id' => channel.inbox.id)
          expect(payload).not_to have_key('configuration_id')
          expect(URI(response.parsed_body.fetch('url')).host).to eq('www.instagram.com')
        end

        it 'keeps a Unified Login inbox on its saved configuration when the default changes' do
          channel = create(:channel_instagram, account: account, auth_type: 'unified_login', configuration_id: 'saved_config')
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('instagram_login')
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token,
                                                                         params: { inbox_id: channel.inbox.id }, as: :json

          query = Rack::Utils.parse_query(URI(response.parsed_body.fetch('url')).query)
          expect(query.fetch('config_id')).to eq('saved_config')
          payload = JWT.decode(query.fetch('state'), 'state_secret', true, algorithm: 'HS256').first
          expect(payload).to include('inbox_id' => channel.inbox.id, 'configuration_id' => 'saved_config')
        end

        it 'rejects reconnecting an inbox from another account' do
          channel = create(:channel_instagram)
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token,
                                                                         params: { inbox_id: channel.inbox.id }, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'rejects reconnecting a different channel type through Instagram' do
          inbox = create(:inbox, account: account)
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token,
                                                                         params: { inbox_id: inbox.id }, as: :json
          expect(response).to have_http_status(:not_found)
        end

        it 'uses Instagram Login when explicitly selected while keeping the configuration ID saved' do
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('instagram_login')
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token, as: :json

          url = URI(response.parsed_body.fetch('url'))
          query = Rack::Utils.parse_query(url.query)
          expect(url.host).to eq('www.instagram.com')
          expect(query).not_to have_key('config_id')
          payload = JWT.decode(query.fetch('state'), 'state_secret', true, algorithm: 'HS256').first
          expect(payload).not_to have_key('configuration_id')
        end

        it 'rejects Unified Login selected without a configuration ID' do
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_LOGIN_METHOD', nil).and_return('unified_login')
          allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_CONFIGURATION_ID', nil).and_return(nil)
          post "/api/v1/accounts/#{account.id}/instagram/authorization", headers: administrator.create_new_auth_token, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq(I18n.t('instagram.missing_credentials'))
        end
      end

      it 'returns unauthorized for agent' do
        post "/api/v1/accounts/#{account.id}/instagram/authorization",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        post "/api/v1/accounts/#{account.id}/instagram/authorization",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['success']).to be true

        instagram_service = Class.new do
          extend InstagramConcern
          extend Instagram::IntegrationHelper
        end
        frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
        response_url = instagram_service.instagram_client.auth_code.authorize_url(
          {
            redirect_uri: "#{frontend_url}/instagram/callback",
            scope: Instagram::IntegrationHelper::REQUIRED_SCOPES.join(','),
            enable_fb_login: '0',
            force_reauth: 'true',
            response_type: 'code',
            state: instagram_service.generate_instagram_token(account.id)
          }
        )
        expect(response.parsed_body['url']).to eq response_url
      end
    end
  end
end
