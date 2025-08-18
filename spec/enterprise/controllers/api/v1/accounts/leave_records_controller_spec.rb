require 'rails_helper'

RSpec.describe 'LeaveRecords API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_user) { create(:user, account: account, role: :agent) }

  describe 'GET #index' do
    let!(:agent_leave_record) { create(:leave_record, account: account, user: agent) }
    let!(:other_user_leave_record) { create(:leave_record, account: account, user: other_user) }

    context 'when authenticated as administrator' do
      it 'returns all leave records in the account' do
        get "/api/v1/accounts/#{account.id}/leave_records",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body.length).to eq(2)
      end
    end

    context 'when authenticated as agent' do
      it 'returns only own leave records' do
        get "/api/v1/accounts/#{account.id}/leave_records",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body.length).to eq(1)
        expect(body[0]['user']['id']).to eq(agent.id)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/leave_records"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }
    let(:other_leave_record) { create(:leave_record, account: account, user: other_user) }

    context 'when authenticated as administrator' do
      it 'shows any leave record in the account' do
        get "/api/v1/accounts/#{account.id}/leave_records/#{other_leave_record.id}",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['id']).to eq(other_leave_record.id)
        expect(body['user']['id']).to eq(other_user.id)
      end
    end

    context 'when authenticated as agent' do
      it 'shows own leave record' do
        get "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['id']).to eq(leave_record.id)
        expect(body['user']['id']).to eq(agent.id)
      end

      it 'denies access to other user leave record' do
        get "/api/v1/accounts/#{account.id}/leave_records/#{other_leave_record.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        leave_record: {
          start_date: 1.week.from_now.to_date,
          end_date: 2.weeks.from_now.to_date,
          leave_type: 'annual',
          reason: 'Vacation time'
        }
      }
    end

    context 'when authenticated as agent' do
      it 'creates a leave record for the current user' do
        expect do
          post "/api/v1/accounts/#{account.id}/leave_records",
               params: valid_params,
               headers: agent.create_new_auth_token
        end.to change(LeaveRecord, :count).by(1)

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['user']['id']).to eq(agent.id)
        expect(body['leave_type']).to eq('annual')
        expect(body['status']).to eq('pending')
      end

      it 'returns validation errors for invalid data' do
        invalid_params = valid_params.deep_merge(
          leave_record: { start_date: nil }
        )

        post "/api/v1/accounts/#{account.id}/leave_records",
             params: invalid_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when authenticated as administrator' do
      it 'creates a leave record for the current user' do
        expect do
          post "/api/v1/accounts/#{account.id}/leave_records",
               params: valid_params,
               headers: administrator.create_new_auth_token
        end.to change(LeaveRecord, :count).by(1)

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['user']['id']).to eq(administrator.id)
      end
    end
  end

  describe 'PUT #update' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }
    let(:other_leave_record) { create(:leave_record, account: account, user: other_user, status: :pending) }
    let(:update_params) do
      {
        leave_record: {
          reason: 'Updated reason'
        }
      }
    end

    context 'when authenticated as administrator' do
      it 'updates any pending leave record in the account' do
        put "/api/v1/accounts/#{account.id}/leave_records/#{other_leave_record.id}",
            params: update_params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['reason']).to eq('Updated reason')
      end
    end

    context 'when authenticated as agent' do
      it 'updates own pending leave record' do
        put "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['reason']).to eq('Updated reason')
      end

      it 'denies updating other user leave record' do
        put "/api/v1/accounts/#{account.id}/leave_records/#{other_leave_record.id}",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end

      it 'denies updating approved leave record' do
        approved_leave_record = create(:leave_record, account: account, user: agent, status: :approved)

        put "/api/v1/accounts/#{account.id}/leave_records/#{approved_leave_record.id}",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }
    let(:other_leave_record) { create(:leave_record, account: account, user: other_user, status: :pending) }

    context 'when authenticated as administrator' do
      it 'deletes any cancellable leave record in the account' do
        expect do
          delete "/api/v1/accounts/#{account.id}/leave_records/#{other_leave_record.id}",
                 headers: administrator.create_new_auth_token
        end.to change(LeaveRecord, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when authenticated as agent' do
      it 'deletes own cancellable leave record' do
        expect do
          delete "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
                 headers: agent.create_new_auth_token
        end.to change(LeaveRecord, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'denies deleting other user leave record' do
        delete "/api/v1/accounts/#{account.id}/leave_records/#{other_leave_record.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end

      it 'denies deleting non-cancellable leave record' do
        non_cancellable_leave_record = create(:leave_record, account: account, user: agent,
                                              status: :approved,
                                              start_date: Date.current,
                                              end_date: Date.current + 2.days)

        delete "/api/v1/accounts/#{account.id}/leave_records/#{non_cancellable_leave_record.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #approve' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }

    context 'when authenticated as administrator' do
      it 'approves the leave record' do
        patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/approve",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['status']).to eq('approved')
        expect(body['approver']['id']).to eq(administrator.id)
      end
    end

    context 'when authenticated as agent' do
      it 'denies approval' do
        patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/approve",
              headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #reject' do
    let(:leave_record) { create(:leave_record, account: account, user: agent, status: :pending) }

    context 'when authenticated as administrator' do
      it 'rejects the leave record' do
        patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/reject",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['status']).to eq('rejected')
        expect(body['approver']['id']).to eq(administrator.id)
      end
    end

    context 'when authenticated as agent' do
      it 'denies rejection' do
        patch "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}/reject",
              headers: agent.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'response format' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }

    it 'returns leave record data in correct format' do
      get "/api/v1/accounts/#{account.id}/leave_records/#{leave_record.id}",
          headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)

      expect(body.keys).to include('id', 'start_date', 'end_date', 'leave_type', 'status', 
                                   'reason', 'duration_in_days', 'created_at', 'updated_at', 'user')
      expect(body['user'].keys).to include('id', 'name', 'email')
    end

    it 'includes approver data when present' do
      approved_leave_record = create(:leave_record, account: account, user: agent, status: :approved)
      approved_leave_record.update!(approver: administrator, approved_at: Time.current)

      get "/api/v1/accounts/#{account.id}/leave_records/#{approved_leave_record.id}",
          headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)

      expect(body['approver']).not_to be_nil
      expect(body['approver'].keys).to include('id', 'name', 'email')
    end
  end
end