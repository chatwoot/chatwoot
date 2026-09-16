require 'rails_helper'

RSpec.describe 'Super Admin User diagnostics', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user, email: 'agent@example.com') }

  describe 'GET /super_admin/user_diagnostics' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/user_diagnostics'

        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'renders the lookup form without a query' do
        get '/super_admin/user_diagnostics'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('User Diagnostics')
      end

      it 'is available on a self hosted installation' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

        get '/super_admin/user_diagnostics'

        expect(response).to have_http_status(:success)
      end

      it 'reports when no user matches the query' do
        get '/super_admin/user_diagnostics', params: { user_query: 'nobody@example.com' }

        expect(response.body).to include('No user found')
      end

      it 'finds a user by id' do
        get '/super_admin/user_diagnostics', params: { user_query: user.id.to_s }

        expect(response.body).to include(user.email)
        expect(response.body).to include(super_admin_user_path(user))
      end

      it 'redirects the retired push diagnostics path to the push tab' do
        get '/super_admin/push_diagnostics', params: { user_query: user.id.to_s }

        expect(response).to redirect_to("/super_admin/user_diagnostics?tab=push&user_query=#{user.id}")
      end

      it 'falls back to the push tab for an unknown tab' do
        get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'nonsense' }

        expect(response.body).to include('Push notification settings')
        expect(response.body).not_to include('Mobile sessions')
      end
    end
  end

  describe 'the mobile tab' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'finds a user by email and lists their mobile sessions' do
      user.user_sessions.create!(
        client_id: 'client-1', browser_name: 'Chatwoot Mobile', browser_version: '4.8.5',
        device_name: 'iPhone', platform_name: 'iPhone 15', platform_version: '26.5.2',
        last_activity_at: Time.current
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('4.8.5')
      expect(response.body).to include('iPhone 15')
      expect(response.body).to include('26.5.2')
    end

    it 'reports the web session count instead of listing web sessions' do
      user.user_sessions.create!(
        client_id: 'web-1', browser_name: 'Chrome', browser_version: '120.0',
        device_name: 'Unknown', platform_name: 'macOS', platform_version: '15.0',
        last_activity_at: Time.current
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

      expect(response.body).to include('No mobile sessions recorded')
      expect(response.body).to include('1 active web session')
      expect(response.body).not_to include('Chrome')
    end

    it 'flags sessions from builds that predate version reporting' do
      user.user_sessions.create!(
        client_id: 'client-legacy', browser_name: 'Chatwoot Mobile', browser_version: nil,
        device_name: 'iPhone', last_activity_at: Time.current
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

      expect(response.body).to include('legacy build')
    end

    it 'does not render session location data' do
      user.user_sessions.create!(
        client_id: 'client-located', browser_name: 'Chatwoot Mobile', browser_version: '4.9.1',
        device_name: 'iPhone', platform_name: 'iPhone 15', platform_version: '26.5.2',
        ip_address: '189.4.1.20', city: 'Sao Paulo', country: 'Brazil', country_code: 'BR',
        last_activity_at: Time.current
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

      expect(response.body).to include('iPhone 15')
      expect(response.body).not_to include('Sao Paulo')
      expect(response.body).not_to include('189.4.1.20')
    end

    it 'leaves every device registration to the push tab' do
      user.notification_subscriptions.create!(
        subscription_type: 'fcm', identifier: 'token-mobile',
        subscription_attributes: { 'device_id' => 'DEVICE-ABC', 'deviceName' => 'Pixel 8' }
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

      expect(response.body).not_to include('Registered devices')
      expect(response.body).not_to include('Pixel 8')
    end

    it 'points at the push tab when an account has every push type off' do
      account = create(:account, name: 'Acme')
      create(:account_user, user: user, account: account)
      user.notification_settings.find_by(account: account).update!(push_flags: 0)

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'mobile' }

      expect(response.body).to include('No push types are enabled for Acme')
      expect(response.body).to include('Review push notification settings')
      expect(response.body).not_to include('A conversation is assigned to the user')
    end
  end

  describe 'the push tab' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'lists every subscription type with the test form' do
      user.notification_subscriptions.create!(
        subscription_type: 'fcm', identifier: 'token-1',
        subscription_attributes: { 'device_id' => 'DEVICE-ABC', 'push_token' => 'token-1' }
      )
      user.notification_subscriptions.create!(
        subscription_type: 'browser_push', identifier: 'endpoint-1',
        subscription_attributes: { 'endpoint' => 'https://fcm.googleapis.com/wp/BROWSERKEY' }
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      expect(response.body).to include('Registered devices (2)')
      expect(response.body).to include('Send Test Push to Selected')
      expect(response.body).to include('fcm.googleapis.com')
      expect(response.body).not_to include('BROWSERKEY')
    end

    it 'reports when no subscription was selected for a test' do
      post '/super_admin/user_diagnostics', params: { user_id: user.id, subscription_ids: [] }

      expect(response).to redirect_to(super_admin_user_diagnostics_path(user_query: user.id, tab: 'push'))
      expect(flash[:alert]).to include('Select at least one subscription to test')
    end

    it 'reports when the user is not found' do
      post '/super_admin/user_diagnostics', params: { user_id: 0, subscription_ids: [1] }

      expect(response).to redirect_to(super_admin_user_diagnostics_path)
      expect(flash[:alert]).to eq('User not found.')
    end

    it 'deletes the selected subscriptions' do
      subscription = user.notification_subscriptions.create!(
        subscription_type: 'fcm', identifier: 'token-delete',
        subscription_attributes: { 'device_id' => 'DEVICE-ABC' }
      )

      post '/super_admin/user_diagnostics/destroy_subscriptions',
           params: { user_id: user.id, subscription_ids: [subscription.id] }

      expect(response).to redirect_to(super_admin_user_diagnostics_path(user_query: user.id, tab: 'push'))
      expect(user.notification_subscriptions.count).to eq(0)
    end

    it 'renders the results of a test send on the push tab' do
      subscription = user.notification_subscriptions.create!(
        subscription_type: 'fcm', identifier: 'token-test',
        subscription_attributes: { 'device_id' => 'DEVICE-ABC', 'push_token' => 'token-test' }
      )
      result = { id: subscription.id, type: 'fcm', device: 'DEVICE', token_tail: '…t-test', status: :failure, message: 'UNREGISTERED' }
      test_service = instance_double(Notification::PushTestService, perform: [result])
      allow(Notification::PushTestService).to receive(:new).and_return(test_service)

      post '/super_admin/user_diagnostics', params: { user_id: user.id, subscription_ids: [subscription.id] }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Results')
      expect(response.body).to include('UNREGISTERED')
    end

    it 'renders the push preference matrix and flags an all-off account' do
      account = create(:account, name: 'Acme')
      create(:account_user, user: user, account: account)
      user.notification_settings.find_by(account: account).update!(push_flags: 0)

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      expect(response.body).to include('Acme')
      expect(response.body).to include('A conversation is assigned to the user')
      expect(response.body).to include('No push types are enabled for Acme')
    end

    it 'hides SLA push types for an account without the SLA feature' do
      account = create(:account, name: 'Acme')
      create(:account_user, user: user, account: account)
      user.notification_settings.find_by(account: account).update!(push_flags: 0)

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      expect(response.body).not_to include('A conversation misses first response SLA')
    end

    it 'lists SLA push types for an account with the SLA feature' do
      account = create(:account, name: 'Acme')
      account.enable_features!('sla')
      create(:account_user, user: user, account: account)
      setting = user.notification_settings.find_by(account: account)
      setting.update!(push_flags: 0)
      setting.push_sla_missed_first_response = true
      setting.save!

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      expect(response.body).to include('A conversation misses first response SLA')
    end

    it 'orders the notification types as the agent preferences screen does' do
      account = create(:account, name: 'Acme')
      create(:account_user, user: user, account: account)

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      labels = ['A new conversation is created', 'A conversation is assigned to the user',
                'The user is mentioned in a conversation',
                'A new message is created in an assigned conversation',
                'A new message is created in a participating conversation']
      expect(response.body.index(labels[0])).to be < response.body.index(labels[1])
      expect(response.body.index(labels[1])).to be < response.body.index(labels[2])
      expect(response.body.index(labels[2])).to be < response.body.index(labels[3])
      expect(response.body.index(labels[3])).to be < response.body.index(labels[4])
    end

    it 'checks the box for an enabled type and leaves the rest unchecked' do
      account = create(:account, name: 'Acme')
      create(:account_user, user: user, account: account)
      setting = user.notification_settings.find_by(account: account)
      setting.update!(push_flags: 0)
      setting.push_conversation_assignment = true
      setting.save!

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      expect(response.body).to include('<input type="checkbox" class="pointer-events-none" checked tabindex="-1"')
      expect(response.body).to include('<input type="checkbox" class="pointer-events-none" tabindex="-1"')
      expect(response.body).not_to include('No push types are enabled')
    end

    it 'renders only allowlisted device attributes' do
      user.notification_subscriptions.create!(
        subscription_type: 'fcm', identifier: 'token-allowlist',
        subscription_attributes: {
          'deviceName' => 'iPhone 15', 'buildNumber' => '3', 'push_token' => 'SECRET-TOKEN',
          'device_id' => 'DEVICE-ABC', 'some_future_field' => 'LEAKED'
        }
      )

      get '/super_admin/user_diagnostics', params: { user_query: user.email, tab: 'push' }

      expect(response.body).to include('iPhone 15')
      expect(response.body).not_to include('translation missing')
      expect(response.body).not_to include('SECRET-TOKEN')
      expect(response.body).not_to include('LEAKED')
      expect(response.body).not_to include('some_future_field')
    end
  end
end
