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
      let!(:notification1) { create(:notification, account: account, user: admin) }
      let!(:notification2) { create(:notification, account: account, user: admin) }

      it 'returns all notifications' do
        get "/api/v1/accounts/#{account.id}/notifications",
            headers: admin.create_new_auth_token,
            as: :json

        response_json = response.parsed_body
        expect(response).to have_http_status(:success)
        expect(response.body).to include(notification1.notification_type)
        expect(response_json['data']['meta']['unread_count']).to eq 2
        expect(response_json['data']['meta']['count']).to eq 2
        # notification appear in descending order
        expect(response_json['data']['payload'].first['id']).to eq notification2.id
        expect(response_json['data']['payload'].first['primary_actor']).not_to be_nil
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/notifications/read_all' do
    let(:admin) { create(:user, account: account, role: :administrator) }
    let!(:notification1) { create(:notification, account: account, user: admin) }
    let!(:notification2) { create(:notification, account: account, user: admin) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/notifications/read_all"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates all the notifications read at' do
        post "/api/v1/accounts/#{account.id}/notifications/read_all",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(notification1.reload.read_at).not_to eq('')
        expect(notification2.reload.read_at).not_to eq('')
      end

      it 'updates only the notifications read at for primary actor when param is passed' do
        post "/api/v1/accounts/#{account.id}/notifications/read_all",
             headers: admin.create_new_auth_token,
             params: {
               primary_actor_id: notification1.primary_actor_id,
               primary_actor_type: notification1.primary_actor_type
             },
             as: :json

        expect(response).to have_http_status(:success)
        expect(notification1.reload.read_at).not_to eq('')
        expect(notification2.reload.read_at).to be_nil
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

  describe 'GET /api/v1/accounts/{account.id}/notifications/unread_count' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/notifications/unread_count"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns notifications unread count' do
        2.times.each { create(:notification, account: account, user: admin) }
        get "/api/v1/accounts/#{account.id}/notifications/unread_count",
            headers: admin.create_new_auth_token,
            as: :json

        response_json = response.parsed_body
        expect(response).to have_http_status(:success)
        expect(response_json).to eq 2
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/notifications/:id' do
    let(:admin) { create(:user, account: account, role: :administrator) }
    let!(:notification) { create(:notification, account: account, user: admin) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/notifications/#{notification.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'deletes the notification' do
        delete "/api/v1/accounts/#{account.id}/notifications/#{notification.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Notification.count).to eq(0)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/notifications/:id/snooze' do
    let(:admin) { create(:user, account: account, role: :administrator) }
    let!(:notification) { create(:notification, account: account, user: admin) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/notifications/#{notification.id}/snooze",
             params: { snoozed_until: DateTime.now.utc + 1.day }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the notification snoozed until' do
        post "/api/v1/accounts/#{account.id}/notifications/#{notification.id}/snooze",
             headers: admin.create_new_auth_token,
             params: { snoozed_until: DateTime.now.utc + 1.day },
             as: :json

        expect(response).to have_http_status(:success)
        expect(notification.reload.snoozed_until).not_to eq('')
        expect(notification.reload.meta['last_snoozed_at']).to be_nil
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/notifications/:id/unread' do
    let(:admin) { create(:user, account: account, role: :administrator) }
    let!(:notification) { create(:notification, account: account, user: admin) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/notifications/#{notification.id}/unread"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the notification read at' do
        post "/api/v1/accounts/#{account.id}/notifications/#{notification.id}/unread",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(notification.reload.read_at).to be_nil
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/notifications/destroy_all' do
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:notification1) { create(:notification, account: account, user: admin) }
    let(:notification2) { create(:notification, account: account, user: admin) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/notifications/destroy_all"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'deletes all the read notifications' do
        expect(Notification::DeleteNotificationJob).to receive(:perform_later).with(admin, type: :read)

        post "/api/v1/accounts/#{account.id}/notifications/destroy_all",
             headers: admin.create_new_auth_token,
             params: { type: 'read' },
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'deletes all the notifications' do
        expect(Notification::DeleteNotificationJob).to receive(:perform_later).with(admin, type: :all)

        post "/api/v1/accounts/#{account.id}/notifications/destroy_all",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
