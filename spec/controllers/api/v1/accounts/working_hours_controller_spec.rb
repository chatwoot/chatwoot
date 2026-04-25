# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Working Hours API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:working_hour) { inbox.working_hours.first }

  describe 'PATCH /api/v1/accounts/:account_id/working_hours/:id' do
    let(:valid_params) do
      { working_hour: { open_hour: 8, open_minutes: 30, close_hour: 18, close_minutes: 0, closed_all_day: false } }
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/working_hours/#{working_hour.id}", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns forbidden' do
        patch "/api/v1/accounts/#{account.id}/working_hours/#{working_hour.id}",
              params: valid_params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the working hour and returns ok' do
        patch "/api/v1/accounts/#{account.id}/working_hours/#{working_hour.id}",
              params: valid_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(working_hour.reload.open_hour).to eq(8)
        expect(working_hour.reload.open_minutes).to eq(30)
      end

      it 'returns not found for a working hour outside the account' do
        other_inbox = create(:inbox)
        other_working_hour = other_inbox.working_hours.first

        patch "/api/v1/accounts/#{account.id}/working_hours/#{other_working_hour.id}",
              params: valid_params,
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
