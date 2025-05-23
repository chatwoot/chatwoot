# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Reports API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  # Create a custom role with report_manage permission
  let!(:custom_role) { create(:custom_role, account: account, permissions: ['report_manage']) }
  let!(:agent_with_role) { create(:user) }
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end

  let(:default_timezone) { 'UTC' }
  let(:start_of_today) { Time.current.in_time_zone(default_timezone).beginning_of_day.to_i }
  let(:end_of_today) { Time.current.in_time_zone(default_timezone).end_of_day.to_i }
  let(:params) { { timezone_offset: Time.zone.utc_offset } }

  before do
    agent_with_role_account_user
  end

  describe 'GET /api/v2/accounts/:account_id/reports' do
    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          metric: 'conversations_count',
          type: :account,
          since: start_of_today.to_s,
          until: end_of_today.to_s
        )
      end

      it 'returns success for agents with report_manage permission' do
        get "/api/v2/accounts/#{account.id}/reports",
            params: params,
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v2/accounts/:account_id/reports/summary' do
    context 'when it is an authenticated user' do
      let(:params) do
        super().merge(
          type: :account,
          since: start_of_today.to_s,
          until: end_of_today.to_s
        )
      end

      it 'returns success for agents with report_manage permission' do
        get "/api/v2/accounts/#{account.id}/reports/summary",
            params: params,
            headers: agent_with_role.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
