require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::PipelineStatuses', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, password: 'Test@123456') }
  let(:headers) { user.create_new_auth_token }

  describe 'GET /api/v1/accounts/:account_id/pipeline_statuses' do
    let!(:pipeline_status1) { create(:pipeline_status, account: account, name: 'New', created_at: 2.days.ago) }
    let!(:pipeline_status2) { create(:pipeline_status, account: account, name: 'Contacted', created_at: 1.day.ago) }

    it 'returns all pipeline statuses for the account' do
      get api_v1_account_pipeline_statuses_url(account_id: account.id), headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['pipeline_statuses']).to be_an(Array)
      expect(body['pipeline_statuses'].size).to eq(2)
    end

    it 'returns pipeline statuses ordered by created_at' do
      get api_v1_account_pipeline_statuses_url(account_id: account.id), headers: headers, as: :json

      body = response.parsed_body
      expect(body['pipeline_statuses'].first['name']).to eq('new')
      expect(body['pipeline_statuses'].second['name']).to eq('contacted')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/pipeline_statuses' do
    let(:valid_params) do
      {
        pipeline_status: {
          name: 'Qualified'
        }
      }
    end

    let(:invalid_params) do
      {
        pipeline_status: {
          name: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new pipeline status' do
        expect do
          post api_v1_account_pipeline_statuses_url(account_id: account.id),
               params: valid_params,
               headers: headers,
               as: :json
        end.to change(PipelineStatus, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns the created pipeline status' do
        post api_v1_account_pipeline_statuses_url(account_id: account.id),
             params: valid_params,
             headers: headers,
             as: :json

        body = response.parsed_body
        expect(body['name']).to eq('qualified')
      end

      it 'associates the pipeline status with the account' do
        post api_v1_account_pipeline_statuses_url(account_id: account.id),
             params: valid_params,
             headers: headers,
             as: :json

        body = response.parsed_body
        expect(body['account_id']).to eq(account.id)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new pipeline status' do
        expect do
          post api_v1_account_pipeline_statuses_url(account_id: account.id),
               params: invalid_params,
               headers: headers,
               as: :json
        end.not_to change(PipelineStatus, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/pipeline_statuses/:id' do
    let!(:pipeline_status) { create(:pipeline_status, account: account, name: 'Old Name') }

    let(:valid_params) do
      {
        pipeline_status: {
          name: 'New Name'
        }
      }
    end

    let(:invalid_params) do
      {
        pipeline_status: {
          name: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the pipeline status' do
        patch api_v1_account_pipeline_status_url(account_id: account.id, id: pipeline_status.id),
              params: valid_params,
              headers: headers,
              as: :json

        expect(response).to have_http_status(:ok)
        pipeline_status.reload
        expect(pipeline_status.name).to eq('new name')
      end

      it 'returns the updated pipeline status' do
        patch api_v1_account_pipeline_status_url(account_id: account.id, id: pipeline_status.id),
              params: valid_params,
              headers: headers,
              as: :json

        body = response.parsed_body
        expect(body['name']).to eq('new name')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the pipeline status' do
        patch api_v1_account_pipeline_status_url(account_id: account.id, id: pipeline_status.id),
              params: invalid_params,
              headers: headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        pipeline_status.reload
        expect(pipeline_status.name).to eq('old name')
      end
    end

    context 'when pipeline status does not exist' do
      it 'returns not found' do
        patch api_v1_account_pipeline_status_url(account_id: account.id, id: 999_999),
              params: valid_params,
              headers: headers,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when pipeline status belongs to another account' do
      let(:other_account) { create(:account) }
      let(:other_pipeline_status) { create(:pipeline_status, account: other_account) }

      it 'returns not found' do
        patch api_v1_account_pipeline_status_url(account_id: account.id, id: other_pipeline_status.id),
              params: valid_params,
              headers: headers,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/pipeline_statuses/:id' do
    let!(:pipeline_status) { create(:pipeline_status, account: account) }

    context 'when pipeline status has no conversations' do
      it 'deletes the pipeline status' do
        expect do
          delete api_v1_account_pipeline_status_url(account_id: account.id, id: pipeline_status.id),
                 headers: headers,
                 as: :json
        end.to change(PipelineStatus, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when pipeline status has assigned conversations' do
      let(:inbox) { create(:inbox, account: account) }
      let!(:conversation) { create(:conversation, account: account, inbox: inbox, pipeline_status: pipeline_status) }

      it 'does not delete the pipeline status' do
        expect do
          delete api_v1_account_pipeline_status_url(account_id: account.id, id: pipeline_status.id),
                 headers: headers,
                 as: :json
        end.not_to change(PipelineStatus, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when pipeline status does not exist' do
      it 'returns not found' do
        delete api_v1_account_pipeline_status_url(account_id: account.id, id: 999_999),
               headers: headers,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when pipeline status belongs to another account' do
      let(:other_account) { create(:account) }
      let(:other_pipeline_status) { create(:pipeline_status, account: other_account) }

      it 'returns not found' do
        delete api_v1_account_pipeline_status_url(account_id: account.id, id: other_pipeline_status.id),
               headers: headers,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
