require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Integrations::Slacks' do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
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
        hook_builder = double
        expect(hook_builder).to receive(:perform).and_return(hook)
        expect(Integrations::Slack::HookBuilder).to receive(:new).and_return(hook_builder)

        post "/api/v1/accounts/#{account.id}/integrations/slack",
             params: { code: SecureRandom.hex },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eql('slack')
      end
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
      it 'updates hook if the channel id is correct' do
        channel_builder = double
        expect(channel_builder).to receive(:update_reference_id).and_return(hook)
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        put "/api/v1/accounts/#{account.id}/integrations/slack",
            params: { channel: SecureRandom.hex },
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['hooks'][0]['id']).to eql(hook.id)
      end

      it 'does not update the hook if the channel id is not correct' do
        channel_builder = double
        expect(channel_builder).to receive(:update_reference_id)
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        put "/api/v1/accounts/#{account.id}/integrations/slack",
            params: { channel: SecureRandom.hex },
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eql('Invalid slack channel. Please try again')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/integrations/slack/list_all_channels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/integrations/slack/list_all_channels", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates hook if the channel id is correct' do
        channel_builder = double
        expect(channel_builder).to receive(:fetch_channels).and_return([{ 'id' => '1', 'name' => 'channel-1' }])
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        get "/api/v1/accounts/#{account.id}/integrations/slack/list_all_channels",
            params: { channel: SecureRandom.hex },
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response).to eql([{ 'id' => '1', 'name' => 'channel-1' }])
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
               headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        expect(Integrations::Hook.find_by(id: hook.id)).to be_nil
      end
    end
  end
end
