require 'rails_helper'

RSpec.describe Api::V1::Accounts::ConversationsController, type: :controller do
  let(:account) { create(:account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe 'POST #toggle_typing_status with bot access token' do
    context 'when it is an authenticated bot agent' do
      before do
        # Tạo access token cho bot agent
        @access_token = agent_bot.access_tokens.create!
        request.headers['api_access_token'] = @access_token.token
      end

      it 'allows bot agent to toggle typing status ON' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             params: { typing_status: 'on', is_private: false },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with('conversation.typing_on', kind_of(Time), { 
            conversation: conversation, 
            user: agent_bot, 
            is_private: false 
          })
      end

      it 'allows bot agent to toggle typing status OFF' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             params: { typing_status: 'off', is_private: false },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with('conversation.typing_off', kind_of(Time), { 
            conversation: conversation, 
            user: agent_bot, 
            is_private: false 
          })
      end

      context 'with Facebook channel' do
        let(:facebook_channel) { create(:channel_facebook_page, account: account) }
        let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
        let(:facebook_conversation) { create(:conversation, account: account, inbox: facebook_inbox) }

        it 'sends typing indicator to Facebook platform when bot agent types' do
          allow(Bot::TypingService).to receive(:new).and_return(double(enable_typing: true))
          
          post "/api/v1/accounts/#{account.id}/conversations/#{facebook_conversation.display_id}/toggle_typing_status",
               params: { typing_status: 'on', is_private: false },
               as: :json

          expect(response).to have_http_status(:success)
          expect(Bot::TypingService).to have_received(:new).with(conversation: facebook_conversation)
        end
      end

      context 'with Instagram channel' do
        let(:instagram_channel) { create(:channel_instagram, account: account) }
        let(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account) }
        let(:instagram_conversation) { create(:conversation, account: account, inbox: instagram_inbox) }

        it 'sends typing indicator to Instagram platform when bot agent types' do
          allow(Bot::TypingService).to receive(:new).and_return(double(enable_typing: true))
          
          post "/api/v1/accounts/#{account.id}/conversations/#{instagram_conversation.display_id}/toggle_typing_status",
               params: { typing_status: 'on', is_private: false },
               as: :json

          expect(response).to have_http_status(:success)
          expect(Bot::TypingService).to have_received(:new).with(conversation: instagram_conversation)
        end
      end
    end

    context 'when bot access token is invalid' do
      before do
        request.headers['api_access_token'] = 'invalid_token'
      end

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             params: { typing_status: 'on', is_private: false },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when conversation does not exist' do
      before do
        @access_token = agent_bot.access_tokens.create!
        request.headers['api_access_token'] = @access_token.token
      end

      it 'returns not found' do
        post "/api/v1/accounts/#{account.id}/conversations/999999/toggle_typing_status",
             params: { typing_status: 'on', is_private: false },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Bot agent permissions' do
    let(:access_token_helper) { Class.new { include AccessTokenAuthHelper }.new }

    it 'includes toggle_typing_status in bot accessible endpoints' do
      expect(AccessTokenAuthHelper::BOT_ACCESSIBLE_ENDPOINTS['api/v1/accounts/conversations'])
        .to include('toggle_typing_status')
    end

    it 'allows bot agent access to toggle_typing_status action' do
      allow(access_token_helper).to receive(:params).and_return({
        controller: 'api/v1/accounts/conversations',
        action: 'toggle_typing_status'
      })

      expect(access_token_helper.send(:agent_bot_accessible?)).to be true
    end
  end
end
