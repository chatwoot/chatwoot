require 'rails_helper'

RSpec.describe 'Contacts bulk actions API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:params) do
    {
      action: 'assign_labels',
      contact_ids: [1, 2],
      labels: %w[vip support]
    }
  end

  describe 'POST /api/v1/accounts/:account_id/contacts/bulk_actions' do
    before { ActiveJob::Base.queue_adapter = :test }

    context 'when user is unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/bulk_actions", params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      it 'enqueues bulk action job with permitted params' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/bulk_actions",
               params: params,
               headers: agent.create_new_auth_token,
               as: :json
        end.to have_enqueued_job(Contacts::BulkActionJob).with(
          account.id,
          agent.id,
          hash_including(
            'action' => 'assign_labels',
            'contact_ids' => [1, 2],
            'labels' => %w[vip support]
          )
        )

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include(
          'success' => true,
          'message' => 'Bulk label assignment enqueued'
        )
      end
    end
  end
end
