require 'rails_helper'

RSpec.describe 'Pathors Voice Inboxes API', type: :request do
  let(:account) { create(:account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let!(:support_channel) { create(:channel_voice, account: account, phone_number: '+886222222222') }
  let!(:sales_channel) { create(:channel_voice, account: account, phone_number: '+886233333333') }

  describe 'GET /api/v1/accounts/{account.id}/pathors/voice_inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/voice_inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent bot' do
      it 'lists the voice inboxes with their number and bot' do
        create(:agent_bot_inbox, inbox: support_channel.inbox, agent_bot: agent_bot, account: account)

        get "/api/v1/accounts/#{account.id}/pathors/voice_inboxes",
            headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        payload = response.parsed_body['payload']
        expect(payload.pluck('phone_number')).to contain_exactly('+886222222222', '+886233333333')

        support = payload.find { |inbox| inbox['phone_number'] == '+886222222222' }
        expect(support['inbox_id']).to eq(support_channel.inbox.id)
        expect(support['agent_bot_id']).to eq(agent_bot.id)
        expect(payload.find { |inbox| inbox['phone_number'] == '+886233333333' }['agent_bot_id']).to be_nil
      end

      it 'filters by number' do
        get "/api/v1/accounts/#{account.id}/pathors/voice_inboxes",
            params: { number: sales_channel.phone_number },
            headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('inbox_id')).to eq([sales_channel.inbox.id])
      end

      it 'returns an empty list for an unknown number' do
        get "/api/v1/accounts/#{account.id}/pathors/voice_inboxes",
            params: { number: '+886299999999' },
            headers: { api_access_token: agent_bot.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to be_empty
      end

      it 'does not leak voice inboxes from another account' do
        other_account = create(:account)
        other_bot = create(:agent_bot, account: other_account)
        create(:channel_voice, account: other_account, phone_number: '+886244444444')

        get "/api/v1/accounts/#{other_account.id}/pathors/voice_inboxes",
            headers: { api_access_token: other_bot.access_token.token }, as: :json

        expect(response.parsed_body['payload'].pluck('phone_number')).to eq(['+886244444444'])
      end
    end

    context 'when the bot belongs to another account' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/voice_inboxes",
            headers: { api_access_token: create(:agent_bot, account: create(:account)).access_token.token }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'lists the voice inboxes' do
        get "/api/v1/accounts/#{account.id}/pathors/voice_inboxes",
            headers: create(:user, account: account, role: :agent).create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].size).to eq(2)
      end
    end
  end
end
