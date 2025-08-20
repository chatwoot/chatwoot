require 'rails_helper'

RSpec.describe 'LeaveRecords API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/leave_records' do
    let!(:agent_leave) { create(:leave_record, account: account, user: agent) }
    let!(:other_leave) { create(:leave_record, account: account, user: other_agent) }

    it 'allows admins to see all leave records' do
      get "/api/v1/accounts/#{account.id}/leave_records",
          headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(json_response.length).to eq(2)
    end

    it 'allows agents to see only their own leave records' do
      get "/api/v1/accounts/#{account.id}/leave_records",
          headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(json_response.length).to eq(1)
      expect(json_response.first['user']['id']).to eq(agent.id)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/leave_records' do
    let(:valid_params) do
      {
        leave_record: {
          start_date: 1.week.from_now.to_date,
          end_date: 2.weeks.from_now.to_date,
          leave_type: 'annual',
          reason: 'Family vacation'
        }
      }
    end

    it 'creates a leave record for the current user' do
      expect do
        post "/api/v1/accounts/#{account.id}/leave_records",
             params: valid_params,
             headers: agent.create_new_auth_token
      end.to change(LeaveRecord, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(json_response['user']['id']).to eq(agent.id)
      expect(json_response['status']).to eq('pending')
    end

    it 'fails with invalid params' do
      post "/api/v1/accounts/#{account.id}/leave_records",
           params: { leave_record: { start_date: nil } },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/leave_records/:id' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }
    let(:update_params) { { leave_record: { reason: 'Updated reason' } } }

    it 'allows updating pending leave records' do
      patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
            params: update_params,
            headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(json_response['reason']).to eq('Updated reason')
    end

    it 'prevents updating approved leave records' do
      leave_record.update!(status: :approved)

      patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
            params: update_params,
            headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq(I18n.t('errors.leave_records.cannot_update_non_pending'))
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/leave_records/:id' do
    let!(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }

    it 'allows deleting cancellable leave records' do
      expect do
        delete "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
               headers: agent.create_new_auth_token
      end.to change(LeaveRecord, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'prevents deleting non-cancellable leave records' do
      leave_record.update!(status: :approved, start_date: Date.current, end_date: Date.current + 2.days)

      delete "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
             headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq(I18n.t('errors.leave_records.cannot_delete'))
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/leave_records/:id/approve' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }

    it 'allows admins to approve leave records' do
      patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/approve",
            headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(json_response['status']).to eq('approved')
      expect(json_response['approved_by']['id']).to eq(admin.id)
    end

    it 'denies agents from approving leave records' do
      patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/approve",
            headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/leave_records/:id/reject' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }

    it 'allows admins to reject leave records' do
      patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/reject",
            headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(json_response['status']).to eq('rejected')
      expect(json_response['approved_by']['id']).to eq(admin.id)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end