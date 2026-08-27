require 'rails_helper'

RSpec.describe 'Super Admin Mobile diagnostics', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user, email: 'agent@example.com') }

  before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

  describe 'GET /super_admin/mobile_diagnostics' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/mobile_diagnostics'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when the installation is not chatwoot cloud' do
      it 'redirects to the super admin root' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/mobile_diagnostics'

        expect(response).to redirect_to(super_admin_root_path)
      end
    end

    context 'when it is an authenticated super admin' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'renders the lookup form without a query' do
        get '/super_admin/mobile_diagnostics'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Mobile App')
      end

      it 'reports when no user matches the query' do
        get '/super_admin/mobile_diagnostics', params: { user_query: 'nobody@example.com' }

        expect(response.body).to include('No user found')
      end

      it 'finds a user by email and lists their mobile sessions' do
        user.user_sessions.create!(
          client_id: 'client-1', browser_name: 'Chatwoot Mobile', browser_version: '4.8.5',
          device_name: 'iPhone', platform_name: 'iPhone 15', platform_version: '26.5.2',
          last_activity_at: Time.current
        )

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('4.8.5')
        expect(response.body).to include('iPhone 15')
        expect(response.body).to include('26.5.2')
      end

      it 'finds a user by id' do
        get '/super_admin/mobile_diagnostics', params: { user_query: user.id.to_s }

        expect(response.body).to include(user.email)
      end

      it 'links out to the user and push diagnostics pages' do
        get '/super_admin/mobile_diagnostics', params: { user_query: user.id.to_s }

        expect(response.body).to include(super_admin_user_path(user))
        expect(response.body).to include(super_admin_push_diagnostics_path(user_query: user.id))
      end

      it 'reports the web session count instead of listing web sessions' do
        user.user_sessions.create!(
          client_id: 'web-1', browser_name: 'Chrome', browser_version: '120.0',
          device_name: 'Unknown', platform_name: 'macOS', platform_version: '15.0',
          last_activity_at: Time.current
        )

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('No mobile sessions recorded')
        expect(response.body).to include('1 active web session')
        expect(response.body).not_to include('Chrome')
      end

      it 'renders the push preference matrix and flags an all-off account' do
        account = create(:account, name: 'Acme')
        create(:account_user, user: user, account: account)
        setting = user.notification_settings.find_by(account: account)
        setting.update!(push_flags: 0)

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('Acme')
        expect(response.body).to include('A conversation is assigned to the user')
        expect(response.body).to include('No push types are enabled for Acme')
      end

      it 'hides SLA push types for an account without the SLA feature' do
        account = create(:account, name: 'Acme')
        create(:account_user, user: user, account: account)
        user.notification_settings.find_by(account: account).update!(push_flags: 0)

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

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

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('A conversation misses first response SLA')
      end

      it 'orders the notification types as the agent preferences screen does' do
        account = create(:account, name: 'Acme')
        create(:account_user, user: user, account: account)

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

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

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('checked tabindex="-1"')
        expect(response.body).to include('<input type="checkbox" class="pointer-events-none" tabindex="-1"')
        expect(response.body).not_to include('No push types are enabled')
      end

      it 'does not flag an account that has at least one push type on' do
        account = create(:account, name: 'Acme')
        create(:account_user, user: user, account: account)
        setting = user.notification_settings.find_by(account: account)
        setting.update!(push_flags: 0)
        setting.push_conversation_assignment = true
        setting.save!

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('A conversation is assigned to the user')
        expect(response.body).not_to include('No push types are enabled')
      end

      it 'does not render session location data' do
        user.user_sessions.create!(
          client_id: 'client-located', browser_name: 'Chatwoot Mobile', browser_version: '4.9.1',
          device_name: 'iPhone', platform_name: 'iPhone 15', platform_version: '26.5.2',
          ip_address: '189.4.1.20', city: 'Sao Paulo', country: 'Brazil', country_code: 'BR',
          last_activity_at: Time.current
        )

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('iPhone 15')
        expect(response.body).not_to include('Sao Paulo')
        expect(response.body).not_to include('189.4.1.20')
      end

      it 'renders only allowlisted device attributes' do
        user.notification_subscriptions.create!(
          subscription_type: 'fcm', identifier: 'token-allowlist',
          subscription_attributes: {
            'deviceName' => 'iPhone 15', 'buildNumber' => '3', 'push_token' => 'SECRET-TOKEN',
            'device_id' => 'DEVICE-ABC', 'some_future_field' => 'LEAKED'
          }
        )

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('iPhone 15')
        expect(response.body).not_to include('SECRET-TOKEN')
        expect(response.body).not_to include('LEAKED')
        expect(response.body).not_to include('some_future_field')
      end

      it 'flags a device holding more than one active subscription' do
        2.times do |i|
          user.notification_subscriptions.create!(
            subscription_type: 'fcm', identifier: "token-#{i}",
            subscription_attributes: { 'device_id' => 'SAME-DEVICE-ABC123', 'push_token' => "token-#{i}" }
          )
        end

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('duplicate')
        expect(response.body).to include('holds more than one active subscription')
      end

      it 'does not flag distinct devices' do
        2.times do |i|
          user.notification_subscriptions.create!(
            subscription_type: 'fcm', identifier: "token-#{i}",
            subscription_attributes: { 'device_id' => "DEVICE-#{i}", 'push_token' => "token-#{i}" }
          )
        end

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).not_to include('more than one active subscription')
      end

      it 'flags sessions from builds that predate version reporting' do
        user.user_sessions.create!(
          client_id: 'client-legacy', browser_name: 'Chatwoot Mobile', browser_version: nil,
          device_name: 'iPhone', last_activity_at: Time.current
        )

        get '/super_admin/mobile_diagnostics', params: { user_query: user.email }

        expect(response.body).to include('legacy build')
      end
    end
  end
end
