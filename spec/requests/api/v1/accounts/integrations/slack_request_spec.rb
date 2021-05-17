require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Integrations::Slacks', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:hook) { create(:integrations_hook, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/integrations/slack' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/integrations/slack", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates hook' do
        hook_builder = Integrations::Slack::HookBuilder.new(account: account, code: SecureRandom.hex)
        expect(hook_builder).to receive(:perform).and_return(hook)
        expect(Integrations::Slack::HookBuilder).to receive(:new).and_return(hook_builder)

        channel_builder = Integrations::Slack::ChannelBuilder.new(hook: hook, channel: 'channel')
        expect(channel_builder).to receive(:perform)
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        post "/api/v1/accounts/#{account.id}/integrations/slack",
             params: { code: SecureRandom.hex },
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eql('slack')
      end
    end

    describe 'PUT /api/v1/accounts/{account.id}/integrations/slack/' do
      context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
          put "/api/v1/accounts/#{account.id}/integrations/slack/", params: {}
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when it is an authenticated user' do
        it 'updates hook' do
          channel_builder = Integrations::Slack::ChannelBuilder.new(hook: hook, channel: 'channel')
          expect(channel_builder).to receive(:perform)

          expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

          put "/api/v1/accounts/#{account.id}/integrations/slack",
              params: { channel: SecureRandom.hex },
              headers: agent.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['app_id']).to eql('slack')
        end
      end
    end

    describe 'DELETE /api/v1/accounts/{account.id}/integrations/slack' do
      context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
          delete "/api/v1/accounts/#{account.id}/integrations/slack", params: {}
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when it is an authenticated user' do
        it 'deletes hook' do
          delete "/api/v1/accounts/#{account.id}/integrations/slack",
                 headers: agent.create_new_auth_token
          expect(response).to have_http_status(:success)
          expect(Integrations::Hook.find_by(id: hook.id)).to be nil
        end
      end
    end
  end
end
