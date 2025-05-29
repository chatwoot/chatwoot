require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Aiagent::Topics', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/aiagent/topics' do
    context 'when it is an un-authenticated user' do
      it 'does not fetch topics' do
        get "/api/v1/accounts/#{account.id}/aiagent/topics",
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'fetches topics for the account' do
        create_list(:aiagent_topic, 3, account: account)
        get "/api/v1/accounts/#{account.id}/aiagent/topics",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:payload].length).to eq(3)
        expect(json_response[:meta]).to eq(
          { total_count: 3, page: 1 }
        )
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/aiagent/topics/{id}' do
    let(:topic) { create(:aiagent_topic, account: account) }

    context 'when it is an un-authenticated user' do
      it 'does not fetch the topic' do
        get "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'fetches the topic' do
        get "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:id]).to eq(topic.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/aiagent/topics' do
    let(:valid_attributes) do
      {
        topic: {
          name: 'New Topic',
          description: 'Topic Description'
        }
      }
    end

    context 'when it is an un-authenticated user' do
      it 'does not create an topic' do
        post "/api/v1/accounts/#{account.id}/aiagent/topics",
             params: valid_attributes,
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'does not create an topic' do
        post "/api/v1/accounts/#{account.id}/aiagent/topics",
             params: valid_attributes,
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'creates a new topic' do
        expect do
          post "/api/v1/accounts/#{account.id}/aiagent/topics",
               params: valid_attributes,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Aiagent::Topic, :count).by(1)

        expect(json_response[:name]).to eq('New Topic')
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/aiagent/topics/{id}' do
    let(:topic) { create(:aiagent_topic, account: account) }
    let(:update_attributes) do
      {
        topic: {
          name: 'Updated Topic'
        }
      }
    end

    context 'when it is an un-authenticated user' do
      it 'does not update the topic' do
        patch "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
              params: update_attributes,
              as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'does not update the topic' do
        patch "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
              params: update_attributes,
              headers: agent.create_new_auth_token,
              as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates the topic' do
        patch "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
              params: update_attributes,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:name]).to eq('Updated Topic')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/aiagent/topics/{id}' do
    let!(:topic) { create(:aiagent_topic, account: account) }

    context 'when it is an un-authenticated user' do
      it 'does not delete the topic' do
        delete "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
               as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'delete the topic' do
        delete "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
               headers: agent.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'deletes the topic' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Aiagent::Topic, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/aiagent/topics/{id}/playground' do
    let(:topic) { create(:aiagent_topic, account: account) }
    let(:valid_params) do
      {
        message_content: 'Hello topic',
        message_history: [
          { role: 'user', content: 'Previous message' },
          { role: 'topic', content: 'Previous response' }
        ]
      }
    end

    context 'when it is an un-authenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}/playground",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'generates a response' do
        chat_service = instance_double(Aiagent::Llm::TopicChatService)
        allow(Aiagent::Llm::TopicChatService).to receive(:new).with(topic: topic).and_return(chat_service)
        allow(chat_service).to receive(:generate_response).and_return({ content: 'Topic response' })

        post "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}/playground",
             params: valid_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(chat_service).to have_received(:generate_response).with(
          valid_params[:message_content],
          valid_params[:message_history]
        )
        expect(json_response[:content]).to eq('Topic response')
      end
    end

    context 'when message_history is not provided' do
      it 'uses empty array as default' do
        params_without_history = { message_content: 'Hello topic' }
        chat_service = instance_double(Aiagent::Llm::TopicChatService)
        allow(Aiagent::Llm::TopicChatService).to receive(:new).with(topic: topic).and_return(chat_service)
        allow(chat_service).to receive(:generate_response).and_return({ content: 'Topic response' })

        post "/api/v1/accounts/#{account.id}/aiagent/topics/#{topic.id}/playground",
             params: params_without_history,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(chat_service).to have_received(:generate_response).with(
          params_without_history[:message_content],
          []
        )
      end
    end
  end
end
