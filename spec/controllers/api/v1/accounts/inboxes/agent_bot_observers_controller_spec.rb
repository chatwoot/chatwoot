require 'rails_helper'

RSpec.describe 'Inbox Agent Bot Observers API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/agent_bot_observers" }

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/agent_bot_observers' do
    it 'returns unauthorized for an unauthenticated user' do
      get base_url

      expect(response).to have_http_status(:unauthorized)
    end

    it 'refuses an agent' do
      get base_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists the observers of this inbox only' do
      create(:agent_bot_observer, inbox: inbox, agent_bot: agent_bot)
      create(:agent_bot_observer, inbox: create(:inbox, account: account), agent_bot: create(:agent_bot, account: account))

      get base_url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.pluck('id')).to eq([agent_bot.id])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/{inbox.id}/agent_bot_observers' do
    it 'refuses an agent' do
      post base_url, headers: agent.create_new_auth_token, params: { agent_bot: agent_bot.id }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'adds the bot as an observer without making it the responder' do
      post base_url, headers: admin.create_new_auth_token, params: { agent_bot: agent_bot.id }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['id']).to eq(agent_bot.id)
      expect(inbox.reload.observer_agent_bots).to eq([agent_bot])
      expect(inbox.agent_bot).to be_nil
      expect(inbox.active_bot?).to be(false)
    end

    it 'answers with the observer it already has' do
      create(:agent_bot_observer, inbox: inbox, agent_bot: agent_bot)

      expect do
        post base_url, headers: admin.create_new_auth_token, params: { agent_bot: agent_bot.id }, as: :json
      end.not_to(change(AgentBotObserver, :count))
      expect(response).to have_http_status(:success)
    end

    # Two adds that overlap both pass the uniqueness validation and race to the unique index; the
    # loser reads the winner's row instead of answering an error for a bot that is observing.
    it 'answers with the row an overlapping add committed first' do
      create(:agent_bot_observer, inbox: inbox, agent_bot: agent_bot)
      allow_any_instance_of(AgentBotObserver).to receive(:save!).and_raise( # rubocop:disable RSpec/AnyInstance
        ActiveRecord::RecordNotUnique.new('duplicate key value violates unique constraint')
      )

      post base_url, headers: admin.create_new_auth_token, params: { agent_bot: agent_bot.id }, as: :json

      expect(response).to have_http_status(:success)
      expect(AgentBotObserver.count).to eq(1)
      expect(inbox.reload.observer_agent_bots).to eq([agent_bot])
    end

    it 'never renders the token of a bot that belongs to no account' do
      global_bot = create(:agent_bot)

      post base_url, headers: admin.create_new_auth_token, params: { agent_bot: global_bot.id }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(global_bot.access_token.token)

      get base_url, headers: admin.create_new_auth_token, as: :json

      expect(response.body).not_to include(global_bot.access_token.token)
    end

    it 'does not accept a bot from another account' do
      foreign_bot = create(:agent_bot, account: create(:account))

      post base_url, headers: admin.create_new_auth_token, params: { agent_bot: foreign_bot.id }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/inboxes/{inbox.id}/agent_bot_observers/:id' do
    it 'refuses an agent' do
      create(:agent_bot_observer, inbox: inbox, agent_bot: agent_bot)

      delete "#{base_url}/#{agent_bot.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'removes the observer' do
      create(:agent_bot_observer, inbox: inbox, agent_bot: agent_bot)

      delete "#{base_url}/#{agent_bot.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(inbox.reload.observer_agent_bots).to be_empty
    end

    it 'answers not found for a bot that does not observe the inbox' do
      delete "#{base_url}/#{agent_bot.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'bot token access' do
    it 'grants a bot without an account of its own nothing on the account it merely observes' do
      global_bot = create(:agent_bot)
      create(:agent_bot_observer, inbox: inbox, agent_bot: global_bot)
      conversation = create(:conversation, account: account, inbox: inbox)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/labels",
          headers: { api_access_token: global_bot.access_token.token },
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
