# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Leaves API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account) }
  let(:agent_account_user) { account.account_users.find_by(user: agent) }
  let(:another_agent) { create(:user, account: account) }

  describe 'GET /api/v1/accounts/:account_id/leaves' do
    context 'when authenticated as an agent' do
      it 'returns only their own leaves' do
        create(:leave, account_user: agent_account_user)
        create(:leave, account_user: account.account_users.find_by(user: another_agent))

        get "/api/v1/accounts/#{account.id}/leaves",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['leaves'].size).to eq(1)
      end
    end

    context 'when authenticated as an admin' do
      it 'returns all leaves in the account' do
        create(:leave, account_user: agent_account_user)
        create(:leave, account_user: account.account_users.find_by(user: another_agent))

        get "/api/v1/accounts/#{account.id}/leaves",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['leaves'].size).to eq(2)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/leaves' do
    context 'when authenticated as an agent' do
      it 'creates a leave request for themselves' do
        leave_params = {
          leave: {
            start_date: Date.current + 1.day,
            end_date: Date.current + 7.days,
            leave_type: 'vacation',
            reason: 'Annual vacation'
          }
        }

        post "/api/v1/accounts/#{account.id}/leaves",
             params: leave_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['leave']['status']).to eq('pending')
        expect(json_response['leave']['leave_type']).to eq('vacation')
      end

      it 'validates date order' do
        leave_params = {
          leave: {
            start_date: Date.current + 7.days,
            end_date: Date.current + 1.day,
            leave_type: 'vacation',
            reason: 'Invalid dates'
          }
        }

        post "/api/v1/accounts/#{account.id}/leaves",
             params: leave_params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['errors']).to include('End date must be after or equal to start date')
      end
    end
  end

  describe 'PUT /api/v1/accounts/:account_id/leaves/:id' do
    let(:leave) { create(:leave, account_user: agent_account_user) }

    context 'when authenticated as the leave owner' do
      it 'updates pending leave' do
        update_params = {
          leave: {
            end_date: Date.current + 10.days,
            reason: 'Extended vacation'
          }
        }

        put "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            params: update_params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['leave']['reason']).to eq('Extended vacation')
      end

      it 'cannot update approved leave' do
        leave.update!(status: 'approved')

        update_params = {
          leave: {
            end_date: Date.current + 10.days
          }
        }

        put "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            params: update_params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/leaves/:id/approve' do
    let(:leave) { create(:leave, account_user: agent_account_user) }

    context 'when authenticated as an admin' do
      it 'approves the leave' do
        post "/api/v1/accounts/#{account.id}/leaves/#{leave.id}/approve",
             params: { comments: 'Approved for vacation' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['leave']['status']).to eq('approved')
        expect(json_response['leave']['approved_by']).to eq(admin.name)
      end
    end

    context 'when authenticated as a regular agent' do
      it 'returns forbidden' do
        post "/api/v1/accounts/#{account.id}/leaves/#{leave.id}/approve",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/leaves/:id/reject' do
    let(:leave) { create(:leave, account_user: agent_account_user) }

    context 'when authenticated as an admin' do
      it 'rejects the leave with reason' do
        post "/api/v1/accounts/#{account.id}/leaves/#{leave.id}/reject",
             params: { reason: 'Not enough coverage' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['leave']['status']).to eq('rejected')
      end

      it 'requires rejection reason' do
        post "/api/v1/accounts/#{account.id}/leaves/#{leave.id}/reject",
             params: { reason: '' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['errors']).to include('Rejection reason is required')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/leaves/:id' do
    context 'when deleting own pending leave' do
      let(:leave) { create(:leave, account_user: agent_account_user) }

      it 'deletes the leave' do
        delete "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
        expect(Leave.find_by(id: leave.id)).to be_nil
      end
    end

    context 'when trying to delete approved leave' do
      let(:leave) { create(:leave, :approved, account_user: agent_account_user) }

      it 'returns forbidden' do
        delete "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:forbidden)
        expect(Leave.find_by(id: leave.id)).to be_present
      end
    end
  end
end
