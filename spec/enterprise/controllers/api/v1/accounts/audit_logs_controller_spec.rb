require 'rails_helper'

RSpec.describe 'Enterprise Audit API', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/audit_logs' do
    context 'when it is an un-authenticated user' do
      it 'does not fetch audit logs associated with the account' do
        get "/api/v1/accounts/#{account.id}/audit_logs",
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated normal user' do
      let(:user) { create(:user, account: account) }

      it 'fetches audit logs associated with the account' do
        get "/api/v1/accounts/#{account.id}/audit_logs",
            headers: user.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    # check for response in parse
    context 'when it is an authenticated admin user' do
      it 'returns empty array if feature is not enabled' do
        get "/api/v1/accounts/#{account.id}/audit_logs",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['audit_logs']).to eql([])
      end

      it 'fetches audit logs associated with the account' do
        account.enable_features(:audit_logs)
        account.save!

        get "/api/v1/accounts/#{account.id}/audit_logs",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['audit_logs'][1]['auditable_type']).to eql('Inbox')
        expect(json_response['audit_logs'][1]['action']).to eql('create')
        expect(json_response['audit_logs'][1]['audited_changes']['name']).to eql(inbox.name)
        expect(json_response['audit_logs'][1]['associated_id']).to eql(account.id)
        # contains audit log for account user as well
        # contains audit logs for account update(enable audit logs)
        expect(json_response.slice('current_page', 'per_page', 'total_entries')).to eql(
          'current_page' => 1,
          'per_page' => 25,
          'total_entries' => 3
        )
      end
    end

    context 'when filtering audit logs as an admin' do
      let!(:jane) { create(:user, name: 'Jane Doe', email: 'jane@example.com', account: account) }
      let!(:john) { create(:user, name: 'John Smith', email: 'john@acme.com', account: account) }
      let!(:inbox_audit) do
        Enterprise::AuditLog.create!(auditable: inbox, associated: account, action: 'update', user: jane, created_at: 10.days.ago)
      end
      let!(:sign_in_audit) do
        Enterprise::AuditLog.create!(auditable: john, associated: account, action: 'sign_in', user: john, created_at: 2.days.ago)
      end

      before do
        account.enable_features(:audit_logs)
        account.save!
      end

      def fetch_audit_logs(params = {})
        get "/api/v1/accounts/#{account.id}/audit_logs",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json
        JSON.parse(response.body)
      end

      it 'filters by auditable types' do
        json_response = fetch_audit_logs(types: ['User'])

        returned_types = json_response['audit_logs'].pluck('auditable_type').uniq
        expect(returned_types).to eq(['User'])
        expect(json_response['audit_logs'].pluck('id')).to include(sign_in_audit.id)
      end

      it 'searches by user email' do
        json_response = fetch_audit_logs(q: 'jane@')

        expect(json_response['audit_logs'].pluck('id')).to eq([inbox_audit.id])
      end

      it 'searches by current email for audits written before an email change' do
        jane.skip_reconfirmation!
        jane.update!(email: 'renamed@example.com')

        json_response = fetch_audit_logs(q: 'renamed@')

        expect(json_response['audit_logs'].pluck('id')).to eq([inbox_audit.id])
      end

      it 'searches by user name' do
        json_response = fetch_audit_logs(q: 'smith')

        expect(json_response['audit_logs'].pluck('id')).to eq([sign_in_audit.id])
        expect(json_response['total_entries']).to eq(1)
      end

      it 'filters by created_at window' do
        json_response = fetch_audit_logs(since: 12.days.ago.to_i, until: 5.days.ago.to_i)

        expect(json_response['audit_logs'].pluck('id')).to eq([inbox_audit.id])
      end

      it 'sorts oldest first when sort is asc' do
        json_response = fetch_audit_logs(sort: 'asc')

        expect(json_response['audit_logs'].first['id']).to eq(inbox_audit.id)
      end

      it 'combines search, type and date filters' do
        json_response = fetch_audit_logs(q: 'jane', types: ['Inbox'], since: 12.days.ago.to_i)

        expect(json_response['audit_logs'].pluck('id')).to eq([inbox_audit.id])
      end

      it 'ignores invalid date params' do
        json_response = fetch_audit_logs(since: 'not-a-date')

        expect(response).to have_http_status(:success)
        expect(json_response['audit_logs'].pluck('id')).to include(inbox_audit.id, sign_in_audit.id)
      end

      it 'ignores epochs the database cannot represent' do
        json_response = fetch_audit_logs(since: 9_999_999_999_999_999)

        expect(response).to have_http_status(:success)
        expect(json_response['audit_logs'].pluck('id')).to include(inbox_audit.id, sign_in_audit.id)
      end

      it 'ignores epochs before the unix epoch' do
        json_response = fetch_audit_logs(since: -253_402_300_799)

        expect(response).to have_http_status(:success)
        expect(json_response['audit_logs'].pluck('id')).to include(inbox_audit.id, sign_in_audit.id)
      end

      it 'ignores malformed types and q params' do
        json_response = fetch_audit_logs(types: { foo: 'bar' }, q: ['not-a-string'])

        expect(response).to have_http_status(:success)
        expect(json_response['audit_logs'].pluck('id')).to include(inbox_audit.id, sign_in_audit.id)
      end
    end
  end
end
