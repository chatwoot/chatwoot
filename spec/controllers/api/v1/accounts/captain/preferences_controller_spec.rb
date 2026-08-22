# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::Preferences', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/preferences' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/captain/preferences",
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns captain config' do
        get "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
        expect(json_response[:features]).not_to have_key(:conversation_completion)
      end
    end

    context 'when it is an admin' do
      it 'returns captain config' do
        get "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
      end

      it 'returns single source model for each feature ignoring overrides' do
        account.update!(captain_models: { 'editor' => 'gpt-4.1' })

        get "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :editor)).to include(
          model: Llm::Config.model,
          selected: Llm::Config.model,
          provider: Llm::Config.provider_for(Llm::Config.model),
          source: 'default'
        )
        expect(json_response.dig(:features, :label_suggestion)).to include(
          model: Llm::Config.model,
          selected: Llm::Config.model,
          provider: Llm::Config.provider_for(Llm::Config.model),
          source: 'default'
        )
      end

      it 'returns the configured model as the assistant default for V1 accounts' do
        get "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :assistant)).to include(
          default: Llm::Config.model,
          selected: Llm::Config.model,
          source: 'default'
        )
      end

      it 'returns the configured model as the assistant default for V2 accounts' do
        account.enable_features!('captain_integration_v2')

        get "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :assistant)).to include(
          default: Llm::Config.model,
          selected: Llm::Config.model,
          source: 'default'
        )
      end

      it 'keeps the configured default when an account override is selected' do
        account.enable_features!('captain_integration_v2')
        account.update!(captain_models: { 'assistant' => 'gpt-5.1' })

        get "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :assistant)).to include(
          default: Llm::Config.model,
          selected: Llm::Config.model,
          source: 'default'
        )
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/captain/preferences' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            params: { captain_models: { editor: 'gpt-4.1-mini' } },
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns forbidden' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: agent.create_new_auth_token,
            params: { captain_models: { editor: 'gpt-4.1-mini' } },
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates captain_models' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { editor: 'gpt-4.1-mini' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
        expect(account.reload.captain_models['editor']).to eq('gpt-4.1-mini')
      end

      it 'persists any captain model feature keys (no allow-list)' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: {
              captain_models: {
                editor: 'gpt-4.1-mini',
                unknown_feature: 'gpt-4.1',
                conversation_completion: 'gpt-4.1'
              }
            },
            as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.captain_models).to eq('editor' => 'gpt-4.1-mini', 'unknown_feature' => 'gpt-4.1', 'conversation_completion' => 'gpt-4.1')
        expect(json_response[:features]).not_to have_key(:conversation_completion)
      end

      it 'accepts any captain model values' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { label_suggestion: 'gpt-5.1' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.captain_models['label_suggestion']).to eq('gpt-5.1')
      end

      it 'removes blank captain model overrides' do
        account.update!(captain_models: { 'editor' => 'gpt-4.1' })

        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { editor: '' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.captain_models).to be_nil
        expect(json_response.dig(:features, :editor)).to include(
          selected: Llm::Config.model,
          provider: Llm::Config.provider_for(Llm::Config.model),
          source: 'default'
        )
      end

      it 'updates captain_models for document FAQ generation' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { document_faq_generation: 'gpt-5.2' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :document_faq_generation, :selected)).to eq(Llm::Config.model)
        expect(account.reload.captain_models['document_faq_generation']).to eq('gpt-5.2')
      end

      it 'updates captain_models for conversation FAQ generation' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { conversation_faq_generation: 'gpt-4.1-mini' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :conversation_faq_generation, :selected)).to eq(Llm::Config.model)
        expect(account.reload.captain_models['conversation_faq_generation']).to eq('gpt-4.1-mini')
      end

      it 'updates captain_models for PDF FAQ generation' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { pdf_faq_generation: 'gpt-5.2' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response.dig(:features, :pdf_faq_generation, :selected)).to eq(Llm::Config.model)
        expect(account.reload.captain_models['pdf_faq_generation']).to eq('gpt-5.2')
      end

      it 'updates captain_features' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_features: { editor: true } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
        expect(account.reload.captain_features['editor']).to be true
      end

      it 'merges with existing captain_models' do
        account.update!(captain_models: { 'editor' => 'gpt-4.1-mini', 'assistant' => 'gpt-5.1' })

        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_models: { editor: 'gpt-4.1' } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
        models = account.reload.captain_models
        expect(models['editor']).to eq('gpt-4.1')
        expect(models['assistant']).to eq('gpt-5.1') # Preserved
      end

      it 'merges with existing captain_features' do
        account.update!(captain_features: { 'editor' => true, 'assistant' => false })

        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: { captain_features: { editor: false } },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
        features = account.reload.captain_features
        expect(features['editor']).to be false
        expect(features['assistant']).to be false # Preserved
      end

      it 'updates both models and features in single request' do
        put "/api/v1/accounts/#{account.id}/captain/preferences",
            headers: admin.create_new_auth_token,
            params: {
              captain_models: { editor: 'gpt-4.1-mini' },
              captain_features: { editor: true }
            },
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:features)
        account.reload
        expect(account.captain_models['editor']).to eq('gpt-4.1-mini')
        expect(account.captain_features['editor']).to be true
      end
    end
  end
end
