require 'rails_helper'

RSpec.describe 'Api::V2::Accounts::PromptsController', type: :request do
  let(:account) { create(:account) }
  # Create test prompts using the factory
  let!(:account_prompt_1) { create(:account_prompt, :greeting, account: account) }
  let!(:account_prompt_2) { create(:account_prompt, :closing, account: account) }
  let!(:account_prompt_3) { create(:account_prompt, account: account, prompt_key: 'follow_up', text: 'Any other questions?') }
  # Create prompts for another account to test authorization
  let!(:other_account_prompt) { create(:account_prompt, account: another_account, prompt_key: 'other_greeting', text: 'Other account greeting') }
  let(:another_account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:user_from_another_account) { create(:user, account: another_account, role: :administrator) }

  before do
    # Enable prompts feature for test accounts
    account.enable_features('prompts')
    another_account.enable_features('prompts')
  end

  describe 'GET /api/v2/accounts/:account_id/prompts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/prompts"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a user from another account' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/prompts",
            headers: user_from_another_account.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'returns success with all account prompts' do
        get "/api/v2/accounts/#{account.id}/prompts",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data).to be_an(Array)
        expect(response_data.length).to eq(3)

        # Verify only prompts from the current account are returned
        prompt_keys = response_data.pluck('prompt_key')
        expect(prompt_keys).to contain_exactly('greeting', 'closing', 'follow_up')

        # Verify no prompts from other accounts are included
        expect(prompt_keys).not_to include('other_greeting')
      end

      it 'returns correct prompt data structure' do
        get "/api/v2/accounts/#{account.id}/prompts",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        first_prompt = response_data.first

        # Verify the response contains the expected fields
        expect(first_prompt).to include(
          'id',
          'prompt_key',
          'text',
          'account_id',
          'created_at',
          'updated_at'
        )

        expect(first_prompt['account_id']).to eq(account.id)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns success with all account prompts' do
        get "/api/v2/accounts/#{account.id}/prompts",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data).to be_an(Array)
        expect(response_data.length).to eq(3)
      end
    end

    context 'when account has no prompts' do
      let(:empty_account) { create(:account) }
      let(:empty_account_admin) { create(:user, account: empty_account, role: :administrator) }

      before do
        # Enable prompts feature for empty account
        empty_account.enable_features('prompts')
      end

      it 'returns success with empty array' do
        get "/api/v2/accounts/#{empty_account.id}/prompts",
            headers: empty_account_admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data).to be_an(Array)
        expect(response_data).to be_empty
      end
    end
  end

  describe 'PATCH /api/v2/accounts/:account_id/prompts/:id' do
    let(:valid_params) do
      {
        prompt: {
          text: 'Updated greeting message',
          prompt_key: 'updated_greeting'
        }
      }
    end

    let(:invalid_params) do
      {
        prompt: {
          text: '',
          prompt_key: ''
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a user from another account' do
      it 'returns unauthorized when trying to update prompt from different account' do
        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: valid_params,
              headers: user_from_another_account.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized when trying to access different account URL' do
        patch "/api/v2/accounts/#{another_account.id}/prompts/#{other_account_prompt.id}",
              params: valid_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'updates the prompt successfully with valid parameters' do
        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: valid_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data['text']).to eq('Updated greeting message')
        expect(response_data['prompt_key']).to eq('updated_greeting')
        expect(response_data['id']).to eq(account_prompt_1.id)

        # Verify the prompt was actually updated in the database
        account_prompt_1.reload
        expect(account_prompt_1.text).to eq('Updated greeting message')
        expect(account_prompt_1.prompt_key).to eq('updated_greeting')
      end

      it 'allows partial updates (text only)' do
        text_only_params = {
          prompt: {
            text: 'Only text updated'
          }
        }

        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: text_only_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data['text']).to eq('Only text updated')
        expect(response_data['prompt_key']).to eq('greeting') # Should remain unchanged
      end

      it 'allows partial updates (prompt_key only)' do
        key_only_params = {
          prompt: {
            prompt_key: 'new_greeting_key'
          }
        }

        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: key_only_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data['prompt_key']).to eq('new_greeting_key')
        expect(response_data['text']).to eq('Hello! How can I help you today?') # Should remain unchanged
      end

      it 'returns unprocessable entity with validation errors for invalid data' do
        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: invalid_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        response_data = response.parsed_body
        expect(response_data).to have_key('text')
        expect(response_data).to have_key('prompt_key')
        expect(response_data['text']).to include("can't be blank")
        expect(response_data['prompt_key']).to include("can't be blank")

        # Verify the prompt was not updated in the database
        account_prompt_1.reload
        expect(account_prompt_1.text).to eq('Hello! How can I help you today?')
        expect(account_prompt_1.prompt_key).to eq('greeting')
      end

      it 'handles special characters in text correctly' do
        special_char_params = {
          prompt: {
            text: 'Hello! @#$%^&*()_+{}|:"<>?[]\\;\',./ Testing special characters.',
            prompt_key: 'special_chars_test'
          }
        }

        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: special_char_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data['text']).to eq('Hello! @#$%^&*()_+{}|:"<>?[]\\;\',./ Testing special characters.')

        # Verify in database
        account_prompt_1.reload
        expect(account_prompt_1.text).to eq('Hello! @#$%^&*()_+{}|:"<>?[]\\;\',./ Testing special characters.')
      end

      it 'handles long text content correctly' do
        long_text = 'A' * 1000
        long_text_params = {
          prompt: {
            text: long_text,
            prompt_key: 'long_text_test'
          }
        }

        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: long_text_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data['text']).to eq(long_text)

        # Verify in database
        account_prompt_1.reload
        expect(account_prompt_1.text).to eq(long_text)
      end

      it 'returns not found for non-existent prompt ID' do
        non_existent_id = 999_999

        patch "/api/v2/accounts/#{account.id}/prompts/#{non_existent_id}",
              params: valid_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an authenticated agent' do
      it 'updates the prompt successfully' do
        patch "/api/v2/accounts/#{account.id}/prompts/#{account_prompt_1.id}",
              params: valid_params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)

        response_data = response.parsed_body
        expect(response_data['text']).to eq('Updated greeting message')
        expect(response_data['prompt_key']).to eq('updated_greeting')
      end
    end

    context 'when updating prompt belonging to another account' do
      it 'returns not found and does not update the prompt' do
        original_text = other_account_prompt.text
        original_key = other_account_prompt.prompt_key

        patch "/api/v2/accounts/#{account.id}/prompts/#{other_account_prompt.id}",
              params: valid_params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)

        # Verify the other account's prompt was not modified
        other_account_prompt.reload
        expect(other_account_prompt.text).to eq(original_text)
        expect(other_account_prompt.prompt_key).to eq(original_key)
      end
    end
  end
end