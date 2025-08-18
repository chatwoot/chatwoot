require 'rails_helper'

RSpec.describe 'Leaves API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_user) { create(:user, account: account, role: :agent) }

  describe 'GET #index' do
    before do
      create(:leave, account: account, user: agent)
      create(:leave, account: account, user: other_user)
    end

    context 'when authenticated as administrator' do
      it 'returns all leaves in the account' do
        get "/api/v1/accounts/#{account.id}/leaves",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['leaves'].length).to eq(2)
      end
    end

    context 'when authenticated as agent' do
      it 'returns only own leaves' do
        get "/api/v1/accounts/#{account.id}/leaves",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['leaves'].length).to eq(1)
        expect(body['leaves'][0]['user']['id']).to eq(agent.id)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/leaves"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    let(:leave) { create(:leave, account: account, user: agent) }
    let(:other_leave) { create(:leave, account: account, user: other_user) }

    context 'when authenticated as administrator' do
      it 'shows any leave in the account' do
        get "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['id']).to eq(leave.id)
      end
    end

    context 'when authenticated as agent viewing own leave' do
      it 'shows the leave' do
        get "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['id']).to eq(leave.id)
        expect(body['user']['id']).to eq(agent.id)
      end
    end

    context 'when authenticated as agent viewing other user leave' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/leaves/#{other_leave.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when leave does not exist' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/leaves/99999",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/leaves/#{leave.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        leave: {
          start_date: 1.week.from_now.to_date,
          end_date: 2.weeks.from_now.to_date,
          leave_type: 'annual',
          reason: 'Annual vacation'
        }
      }
    end

    context 'when authenticated as administrator' do
      it 'creates a leave for current user' do
        expect do
          post "/api/v1/accounts/#{account.id}/leaves",
               params: valid_params,
               headers: administrator.create_new_auth_token
        end.to change(Leave, :count).by(1)

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['leave_type']).to eq('annual')
        expect(body['user']['id']).to eq(administrator.id)
      end

      it 'creates leave with other type' do
        params = valid_params.merge(leave: valid_params[:leave].merge(leave_type: 'other'))

        post "/api/v1/accounts/#{account.id}/leaves",
             params: params,
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['leave_type']).to eq('other')
      end
    end

    context 'when authenticated as agent' do
      it 'creates a leave for current user' do
        expect do
          post "/api/v1/accounts/#{account.id}/leaves",
               params: valid_params,
               headers: agent.create_new_auth_token
        end.to change(Leave, :count).by(1)

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['user']['id']).to eq(agent.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors for missing start date' do
        invalid_params = valid_params.merge(leave: valid_params[:leave].except(:start_date))

        post "/api/v1/accounts/#{account.id}/leaves",
             params: invalid_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors for end date before start date' do
        invalid_params = valid_params.merge(
          leave: valid_params[:leave].merge(
            start_date: 2.weeks.from_now.to_date,
            end_date: 1.week.from_now.to_date
          )
        )

        post "/api/v1/accounts/#{account.id}/leaves",
             params: invalid_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors for past start date on pending leave' do
        invalid_params = valid_params.merge(
          leave: valid_params[:leave].merge(
            start_date: 1.week.ago.to_date,
            end_date: Date.current
          )
        )

        post "/api/v1/accounts/#{account.id}/leaves",
             params: invalid_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/leaves",
             params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT #update' do
    let(:leave) { create(:leave, account: account, user: agent, status: :pending) }
    let(:other_leave) { create(:leave, account: account, user: other_user, status: :pending) }
    let(:approved_leave) { create(:leave, account: account, user: agent, status: :approved) }

    let(:update_params) do
      {
        leave: {
          reason: 'Updated reason'
        }
      }
    end

    context 'when authenticated as administrator' do
      it 'updates any pending leave' do
        put "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            params: update_params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['reason']).to eq('Updated reason')
      end

      it 'cannot update non-pending leaves' do
        put "/api/v1/accounts/#{account.id}/leaves/#{approved_leave.id}",
            params: update_params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent' do
      it 'updates own pending leave' do
        put "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['reason']).to eq('Updated reason')
      end

      it 'cannot update other user leave' do
        put "/api/v1/accounts/#{account.id}/leaves/#{other_leave.id}",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'cannot update non-pending leaves' do
        put "/api/v1/accounts/#{account.id}/leaves/#{approved_leave.id}",
            params: update_params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when leave does not exist' do
      it 'returns not found' do
        put "/api/v1/accounts/#{account.id}/leaves/99999",
            params: update_params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/leaves/#{leave.id}",
            params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:pending_leave) { create(:leave, account: account, user: agent, status: :pending) }
    let(:approved_future_leave) do
      create(:leave, account: account, user: agent, status: :approved,
                     start_date: 1.month.from_now.to_date, end_date: 1.month.from_now.to_date + 5.days)
    end
    let(:approved_past_leave) do
      create(:leave, account: account, user: agent, status: :approved,
                     start_date: 1.week.ago.to_date, end_date: 3.days.ago.to_date)
    end
    let(:other_leave) { create(:leave, account: account, user: other_user, status: :pending) }

    context 'when authenticated as administrator' do
      it 'deletes cancellable leaves' do
        expect do
          delete "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}",
                 headers: administrator.create_new_auth_token
        end.to change(Leave, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it 'deletes approved future leaves' do
        expect do
          delete "/api/v1/accounts/#{account.id}/leaves/#{approved_future_leave.id}",
                 headers: administrator.create_new_auth_token
        end.to change(Leave, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it 'cannot delete non-cancellable leaves' do
        delete "/api/v1/accounts/#{account.id}/leaves/#{approved_past_leave.id}",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent' do
      it 'deletes own cancellable leaves' do
        expect do
          delete "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}",
                 headers: agent.create_new_auth_token
        end.to change(Leave, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it 'cannot delete other user leaves' do
        delete "/api/v1/accounts/#{account.id}/leaves/#{other_leave.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when leave does not exist' do
      it 'returns not found' do
        delete "/api/v1/accounts/#{account.id}/leaves/99999",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH #approve' do
    let(:pending_leave) { create(:leave, account: account, user: agent, status: :pending) }
    let(:approved_leave) { create(:leave, account: account, user: agent, status: :approved) }

    context 'when authenticated as administrator' do
      it 'approves pending leave' do
        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/approve",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['status']).to eq('approved')
        expect(body['approver']['id']).to eq(administrator.id)
        expect(body['approved_at']).not_to be_nil

        pending_leave.reload
        expect(pending_leave.status).to eq('approved')
        expect(pending_leave.approver).to eq(administrator)
      end

      it 'updates approved_at timestamp' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/approve",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        pending_leave.reload
        expect(pending_leave.approved_at.to_i).to eq(freeze_time.to_i)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/approve",
              headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when leave does not exist' do
      it 'returns not found' do
        patch "/api/v1/accounts/#{account.id}/leaves/99999/approve",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/approve"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH #reject' do
    let(:pending_leave) { create(:leave, account: account, user: agent, status: :pending) }
    let(:rejected_leave) { create(:leave, account: account, user: agent, status: :rejected) }

    context 'when authenticated as administrator' do
      it 'rejects pending leave' do
        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/reject",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['status']).to eq('rejected')
        expect(body['approver']['id']).to eq(administrator.id)
        expect(body['approved_at']).not_to be_nil

        pending_leave.reload
        expect(pending_leave.status).to eq('rejected')
        expect(pending_leave.approver).to eq(administrator)
      end

      it 'updates approved_at timestamp on rejection' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/reject",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        pending_leave.reload
        expect(pending_leave.approved_at.to_i).to eq(freeze_time.to_i)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/reject",
              headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when leave does not exist' do
      it 'returns not found' do
        patch "/api/v1/accounts/#{account.id}/leaves/99999/reject",
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/leaves/#{pending_leave.id}/reject"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Business logic scenarios' do
    describe 'leave overlap detection' do
      let(:existing_leave) do
        create(:leave, account: account, user: agent, status: :approved,
                       start_date: 1.month.from_now.to_date,
                       end_date: 1.month.from_now.to_date + 5.days)
      end

      it 'allows non-overlapping leaves' do
        existing_leave

        params = {
          leave: {
            start_date: 2.months.from_now.to_date,
            end_date: 2.months.from_now.to_date + 3.days,
            leave_type: 'annual',
            reason: 'Second vacation'
          }
        }

        post "/api/v1/accounts/#{account.id}/leaves",
             params: params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
      end
    end

    describe 'leave duration calculation' do
      it 'includes duration in response' do
        params = {
          leave: {
            start_date: 1.week.from_now.to_date,
            end_date: 1.week.from_now.to_date + 4.days,
            leave_type: 'annual',
            reason: 'Five day vacation'
          }
        }

        post "/api/v1/accounts/#{account.id}/leaves",
             params: params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['duration_in_days']).to eq(5)
      end
    end

    describe 'approver validation' do
      let(:non_admin_approver) { create(:user, account: account, role: :agent) }

      before do
        # Ensure approver is linked to account
        create(:account_user, account: account, user: non_admin_approver, role: :agent)
        create(:account_user, account: account, user: administrator, role: :administrator)
      end

      it 'rejects leave approval by non-administrator' do
        leave = create(:leave, account: account, user: agent, status: :pending)

        # Simulate manual update with non-admin approver (would fail validation)
        expect do
          leave.update!(approved_by_id: non_admin_approver.id, status: :approved)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
