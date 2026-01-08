# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aloo Assistants API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/aloo/assistants' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:assistant) { create(:aloo_assistant, account: account) }

      it 'returns all assistants' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body
        expect(json_response['meta']['total_count']).to eq(1)
        expect(json_response['payload']).to be_an(Array)
        expect(json_response['payload'].length).to eq(1)
        expect(json_response['payload'].first['name']).to eq(assistant.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/aloo/assistants' do
    let(:valid_params) do
      {
        assistant: {
          name: 'Test Assistant',
          description: 'A test assistant',
          tone: 'friendly',
          formality: 'medium',
          empathy_level: 'medium',
          verbosity: 'balanced',
          emoji_usage: 'minimal',
          greeting_style: 'warm',
          language: 'en'
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'creates an assistant with valid params' do
        expect do
          post "/api/v1/accounts/#{account.id}/aloo/assistants",
               headers: administrator.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(Aloo::Assistant, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['name']).to eq('Test Assistant')
      end

      it 'returns error when name is blank' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: { assistant: valid_params[:assistant].merge(name: '') },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to include("Name can't be blank")
      end

      it 'returns error when name is missing' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: { assistant: valid_params[:assistant].except(:name) },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates assistant with personality settings' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: {
               assistant: valid_params[:assistant].merge(
                 tone: 'professional',
                 formality: 'high',
                 empathy_level: 'high'
               )
             },
             as: :json

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['personality']['tone']).to eq('professional')
        expect(json_response['personality']['formality']).to eq('high')
        expect(json_response['personality']['empathy_level']).to eq('high')
      end

      it 'creates assistant with Arabic dialect' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: administrator.create_new_auth_token,
             params: {
               assistant: valid_params[:assistant].merge(
                 language: 'ar',
                 dialect: 'EG'
               )
             },
             as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['language']).to eq('ar')
        expect(response.parsed_body['dialect']).to eq('EG')
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns forbidden' do
        post "/api/v1/accounts/#{account.id}/aloo/assistants",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/aloo/assistants/{id}' do
    let!(:assistant) { create(:aloo_assistant, account: account, name: 'Original Name') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              params: { assistant: { name: 'Updated Name' } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'updates the assistant name' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              headers: administrator.create_new_auth_token,
              params: { assistant: { name: 'Updated Name' } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(assistant.reload.name).to eq('Updated Name')
      end

      it 'updates personality settings' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              headers: administrator.create_new_auth_token,
              params: { assistant: { tone: 'professional', formality: 'high' } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(assistant.reload.tone).to eq('professional')
        expect(assistant.reload.formality).to eq('high')
      end

      it 'returns error for invalid tone' do
        patch "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
              headers: administrator.create_new_auth_token,
              params: { assistant: { tone: 'invalid_tone' } },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/aloo/assistants/{id}' do
    let!(:assistant) { create(:aloo_assistant, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'deletes the assistant' do
        expect do
          delete "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to change(Aloo::Assistant, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/aloo/assistants/{id}' do
    let!(:assistant) { create(:aloo_assistant, account: account) }

    context 'when it is an authenticated administrator' do
      it 'returns the assistant details' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{assistant.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(assistant.id)
        expect(response.parsed_body['name']).to eq(assistant.name)
        expect(response.parsed_body['personality']).to be_present
        expect(response.parsed_body['features']).to be_present
      end
    end

    context 'when assistant does not exist' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/999999",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when accessing another account assistant' do
      let(:other_account) { create(:account) }
      let!(:other_assistant) { create(:aloo_assistant, account: other_account) }

      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/aloo/assistants/#{other_assistant.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
