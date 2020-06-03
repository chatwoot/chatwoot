require 'rails_helper'

RSpec.describe 'Notifications API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/notifications' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/notifications"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:notification) { create(:notification, account: account, user: admin) }

      it 'returns all notifications' do
        get "/api/v1/accounts/#{account.id}/notifications",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(notification.notification_type)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/notifications/:id' do
    let(:admin) { create(:user, account: account, role: :administrator) }
    let!(:notification) { create(:notification, account: account, user: admin) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/notifications/#{notification.id}",
            params: { read_at: true }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the notification read at' do
        patch "/api/v1/accounts/#{account.id}/notifications/#{notification.id}",
              headers: admin.create_new_auth_token,
              params: { read_at: true },
              as: :json

        expect(response).to have_http_status(:success)
        expect(notification.reload.read_at).not_to eq('')
      end
    end
  end
end
