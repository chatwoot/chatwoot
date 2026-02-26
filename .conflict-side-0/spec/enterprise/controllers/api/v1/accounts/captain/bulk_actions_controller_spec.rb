require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::BulkActions', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:pending_responses) do
    create_list(
      :captain_assistant_response,
      2,
      assistant: assistant,
      account: account,
      status: 'pending'
    )
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'POST /api/v1/accounts/:account_id/captain/bulk_actions' do
    context 'when approving responses' do
      let(:valid_params) do
        {
          type: 'AssistantResponse',
          ids: pending_responses.map(&:id),
          fields: { status: 'approve' }
        }
      end

      it 'approves the responses and returns the updated records' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        # Verify responses were approved
        pending_responses.each do |response|
          expect(response.reload.status).to eq('approved')
        end
      end
    end

    context 'when deleting responses' do
      let(:delete_params) do
        {
          type: 'AssistantResponse',
          ids: pending_responses.map(&:id),
          fields: { status: 'delete' }
        }
      end

      it 'deletes the responses and returns an empty array' do
        expect do
          post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
               params: delete_params,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Captain::AssistantResponse, :count).by(-2)

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])

        # Verify responses were deleted
        pending_responses.each do |response|
          expect { response.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'with invalid type' do
      let(:invalid_params) do
        {
          type: 'InvalidType',
          ids: pending_responses.map(&:id),
          fields: { status: 'approve' }
        }
      end

      it 'returns unprocessable entity status' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:success]).to be(false)

        # Verify no changes were made
        pending_responses.each do |response|
          expect(response.reload.status).to eq('pending')
        end
      end
    end

    context 'with missing parameters' do
      let(:missing_params) do
        {
          type: 'AssistantResponse',
          fields: { status: 'approve' }
        }
      end

      it 'returns unprocessable entity status' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: missing_params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:success]).to be(false)

        # Verify no changes were made
        pending_responses.each do |response|
          expect(response.reload.status).to eq('pending')
        end
      end
    end

    context 'with unauthorized user' do
      let(:unauthorized_user) { create(:user, account: create(:account)) }

      it 'returns unauthorized status' do
        post "/api/v1/accounts/#{account.id}/captain/bulk_actions",
             params: { type: 'AssistantResponse', ids: [1], fields: { status: 'approve' } },
             headers: unauthorized_user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)

        # Verify no changes were made
        pending_responses.each do |response|
          expect(response.reload.status).to eq('pending')
        end
      end
    end
  end
end
