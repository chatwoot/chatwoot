require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'PATCH /api/v1/accounts/{account.id}' do
    let(:assistant_models) { Llm::Models.models_for(:assistant) }
    let(:assistant_model) { assistant_models.first }
    let(:updated_assistant_model) { assistant_models.second || assistant_model }
    let(:copilot_model) { Llm::Models.models_for(:copilot).first }
    let(:editor_model) { Llm::Models.models_for(:editor).first }
    let(:account) do
      create(:account, settings: {
               'captain_models' => {
                 'assistant' => assistant_model,
                 'copilot' => copilot_model
               },
               'captain_features' => {
                 'assistant' => true,
                 'help_center_search' => true
               }
             })
    end
    let(:admin) { create(:user, account: account, role: :administrator) }

    it 'permits captain settings keys and ignores unknown ones' do
      params = {
        captain_models: {
          editor: editor_model,
          assistant: updated_assistant_model,
          unknown: 'nope'
        },
        captain_features: {
          assistant: false,
          editor: true,
          unknown: true
        }
      }

      patch "/api/v1/accounts/#{account.id}",
            headers: admin.create_new_auth_token,
            params: params,
            as: :json

      expect(response).to be_successful
      account.reload
      expect(account.settings['captain_models']).to eq(
        {
          'assistant' => updated_assistant_model,
          'copilot' => copilot_model,
          'editor' => editor_model
        }
      )
      expect(account.settings['captain_features']).to eq(
        {
          'assistant' => false,
          'help_center_search' => true,
          'editor' => true
        }
      )
    end

    it 'keeps captain settings when no captain params are sent' do
      existing_models = account.settings['captain_models']
      existing_features = account.settings['captain_features']

      patch "/api/v1/accounts/#{account.id}",
            headers: admin.create_new_auth_token,
            params: { name: 'Updated Account' },
            as: :json

      expect(response).to be_successful
      account.reload
      expect(account.settings['captain_models']).to eq(existing_models)
      expect(account.settings['captain_features']).to eq(existing_features)
      expect(account.name).to eq('Updated Account')
    end

    it 'rejects invalid captain models' do
      params = {
        captain_models: {
          assistant: 'invalid-model'
        }
      }

      patch "/api/v1/accounts/#{account.id}",
            headers: admin.create_new_auth_token,
            params: params,
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include('not a valid model')
      account.reload
      expect(account.settings['captain_models']).to eq(
        {
          'assistant' => assistant_model,
          'copilot' => copilot_model
        }
      )
    end
  end
end
