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

  before do
    AppliedSla.destroy_all
  end

  describe 'GET /api/v1/accounts/{account.id}/applied_slas/metrics' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/applied_slas/metrics"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the sla metrics' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 1)
        expect(body).to include('number_of_sla_misses' => 1)
        expect(body).to include('hit_rate' => '0.0%')
      end

      it 'filters sla metrics based on a date range' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { since: 5.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 1)
        expect(body).to include('number_of_sla_misses' => 0)
        expect(body).to include('hit_rate' => '100%')
      end

      it 'filters sla metrics based on a date range and agent ids' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation3, created_at: 3.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { agent_ids: [agent2.id] },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 3)
        expect(body).to include('number_of_sla_misses' => 1)
        expect(body).to include('hit_rate' => '66.67%')
      end

      it 'filters sla metrics based on sla policy ids' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy2, conversation: conversation2, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { sla_policy_id: sla_policy1.id },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 2)
        expect(body).to include('number_of_sla_misses' => 1)
        expect(body).to include('hit_rate' => '50.0%')
      end

      it 'filters sla metrics based on labels' do
        conversation2.update_labels('label1')
        conversation3.update_labels('label1')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation3, created_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/applied_slas/metrics",
            params: { label_list: 'label1' },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('total_applied_slas' => 2)
        expect(body).to include('number_of_sla_misses' => 1)
        expect(body).to include('hit_rate' => '50.0%')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/applied_slas/download' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/applied_slas/download"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns a CSV file with breached conversations' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, sla_status: 'missed')
        conversation1.update!(status: 'open')
        conversation2.update!(status: 'resolved')

        get "/api/v1/accounts/#{account.id}/applied_slas/download",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Type']).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment; filename=breached_conversation.csv')

        csv_data = CSV.parse(response.body)
        csv_data.reject! { |row| row.all?(&:nil?) }
        expect(csv_data.size).to eq(3)
        expect(csv_data[1][0].to_i).to eq(conversation1.display_id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/applied_slas' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/applied_slas"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the applied slas' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, sla_status: 'missed')
        get "/api/v1/accounts/#{account.id}/applied_slas",
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body['payload'].size).to eq(1)
        expect(body['payload'].first).to include('applied_sla')
        expect(body['payload'].first['conversation']['id']).to eq(conversation2.id)
        expect(body['meta']).to include('count' => 1)
      end

      it 'filters applied slas based on a date range' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas",
            params: { since: 5.days.ago.to_time.to_i.to_s, until: Time.zone.today.to_time.to_i.to_s },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body['payload'].size).to eq(1)
      end

      it 'filters applied slas based on a date range and agent ids' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago)
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation3, created_at: 3.days.ago, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'active_with_misses')

        get "/api/v1/accounts/#{account.id}/applied_slas",
            params: { agent_ids: [agent2.id] },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body['payload'].size).to eq(2)
      end

      it 'filters applied slas based on sla policy ids' do
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2)
        create(:applied_sla, sla_policy: sla_policy2, conversation: conversation2, sla_status: 'active_with_misses')

        get "/api/v1/accounts/#{account.id}/applied_slas",
            params: { sla_policy_id: sla_policy1.id },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body['payload'].size).to eq(1)
      end

      it 'filters applied slas based on labels' do
        conversation2.update_labels('label1')
        conversation3.update_labels('label1')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation1, created_at: 10.days.ago, sla_status: 'active_with_misses')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation2, created_at: 3.days.ago, sla_status: 'missed')
        create(:applied_sla, sla_policy: sla_policy1, conversation: conversation3, created_at: 3.days.ago, sla_status: 'missed')

        get "/api/v1/accounts/#{account.id}/applied_slas",
            params: { label_list: 'label1' },
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body['payload'].size).to eq(2)
      end
    end
  end
end
