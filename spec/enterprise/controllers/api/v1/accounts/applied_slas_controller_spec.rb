require 'rails_helper'

RSpec.describe 'Applied SLAs API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent1) { create(:user, account: account, role: :agent) }
  let(:agent2) { create(:user, account: account, role: :agent) }
  let(:conversation1) { create(:conversation, account: account, assignee: agent1) }
  let(:conversation2) { create(:conversation, account: account, assignee: agent2) }
  let(:conversation3) { create(:conversation, account: account, assignee: agent2) }
  let(:sla_policy1) { create(:sla_policy, account: account) }
  let(:sla_policy2) { create(:sla_policy, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/applied_slas/metrics' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/applied_slas/metrics"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the sla metrics' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1)
        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 1)
        expect(body).to include('number_of_sla_breaches' => 0)
      end

      it 'filters sla metrics based on a date range' do
        AppliedSla.destroy_all
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { since: 5.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 1)
        expect(body).to include('number_of_sla_breaches' => 0)
      end

      it 'filters sla metrics based on a date range and agent ids' do
        AppliedSla.destroy_all
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation3, created_at: 3.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { agent_ids: [agent2.id] },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 3)
        expect(body).to include('number_of_sla_breaches' => 1)
      end

      it 'filters sla metrics based on sla policy ids' do
        AppliedSla.destroy_all
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy2, conversation: conversation2, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { sla_policy_id: sla_policy1.id },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 2)
        expect(body).to include('number_of_sla_breaches' => 1)
      end

      it 'filters sla metrics based on labels' do
        AppliedSla.destroy_all
        conversation2.update_labels('label1')
        conversation3.update_labels('label1')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation3, created_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { label_list: ['label1'] },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 2)
        expect(body).to include('number_of_sla_breaches' => 1)
      end
    end
  end
end
