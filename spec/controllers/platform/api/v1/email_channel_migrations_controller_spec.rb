require 'rails_helper'

RSpec.describe 'Platform Email Channel Migrations API', type: :request do
  let!(:account) { create(:account) }
  let(:platform_app) { create(:platform_app) }
  let(:base_url) { "/platform/api/v1/accounts/#{account.id}/email_channel_migrations" }
  let(:headers) { { api_access_token: platform_app.access_token.token } }

  let(:google_provider_config) do
    { access_token: 'ya29.test-access-token', refresh_token: '1//test-refresh-token', expires_on: 1.hour.from_now.to_s }
  end

  let(:valid_migration_params) do
    {
      migrations: [
        {
          email: 'support@example.com',
          provider: 'google',
          provider_config: google_provider_config,
          inbox_name: 'Migrated Support'
        }
      ]
    }
  end

  before do
    create(:platform_app_permissible, platform_app: platform_app, permissible: account)
  end

  describe 'POST /platform/api/v1/accounts/:account_id/email_channel_migrations' do
    context 'when unauthenticated' do
      it 'returns unauthorized without token' do
        with_modified_env EMAIL_CHANNEL_MIGRATION: 'true' do
          post base_url, as: :json
          expect(response).to have_http_status(:unauthorized)
        end
      end

      it 'returns unauthorized with invalid token' do
        with_modified_env EMAIL_CHANNEL_MIGRATION: 'true' do
          post base_url, params: valid_migration_params, headers: { api_access_token: 'invalid' }, as: :json
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'when account is not permissible' do
      let(:other_account) { create(:account) }
      let(:other_url) { "/platform/api/v1/accounts/#{other_account.id}/email_channel_migrations" }

      it 'returns unauthorized' do
        with_modified_env EMAIL_CHANNEL_MIGRATION: other_account.id.to_s do
          post other_url, params: valid_migration_params, headers: headers, as: :json
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'when account is not in allowed list' do
      it 'returns forbidden' do
        with_modified_env EMAIL_CHANNEL_MIGRATION: '' do
          post base_url, params: valid_migration_params, headers: headers, as: :json
          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body['error']).to eq('Email channel migration is not enabled')
        end
      end
    end

    context 'when authenticated with permissible account' do
      around do |example|
        with_modified_env EMAIL_CHANNEL_MIGRATION: 'true' do
          example.run
        end
      end

      it 'creates a google email channel and inbox' do
        expect do
          post base_url, params: valid_migration_params, headers: headers, as: :json
        end.to change(Channel::Email, :count).by(1).and change(Inbox, :count).by(1)

        expect(response).to have_http_status(:ok)
        result = response.parsed_body['results'].first
        expect(result['status']).to eq('success')
        expect(result['email']).to eq('support@example.com')
        expect(result['inbox_id']).to be_present
        expect(result['channel_id']).to be_present
      end

      it 'sets correct google channel attributes' do
        post base_url, params: valid_migration_params, headers: headers, as: :json

        channel = Channel::Email.find(response.parsed_body['results'].first['channel_id'])
        expect(channel.provider).to eq('google')
        expect(channel.imap_enabled).to be(true)
        expect(channel.imap_address).to eq('imap.gmail.com')
        expect(channel.imap_port).to eq(993)
        expect(channel.imap_login).to eq('support@example.com')
        expect(channel.provider_config['refresh_token']).to eq('1//test-refresh-token')
      end

      it 'sets correct inbox attributes' do
        post base_url, params: valid_migration_params, headers: headers, as: :json

        inbox = Inbox.find(response.parsed_body['results'].first['inbox_id'])
        expect(inbox.name).to eq('Migrated Support')
        expect(inbox.account_id).to eq(account.id)
      end

      it 'creates a microsoft email channel with correct defaults' do
        params = {
          migrations: [
            {
              email: 'support@outlook.com',
              provider: 'microsoft',
              provider_config: { access_token: 'test', refresh_token: 'test', expires_on: 1.hour.from_now.to_s }
            }
          ]
        }

        post base_url, params: params, headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        result = response.parsed_body['results'].first
        channel = Channel::Email.find(result['channel_id'])

        expect(channel.provider).to eq('microsoft')
        expect(channel.imap_address).to eq('outlook.office365.com')
      end

      it 'uses default inbox name when not provided' do
        params = { migrations: [{ email: 'test@example.com', provider: 'google', provider_config: google_provider_config }] }

        post base_url, params: params, headers: headers, as: :json

        inbox = Inbox.find(response.parsed_body['results'].first['inbox_id'])
        expect(inbox.name).to eq('Migrated Google: test@example.com')
      end

      it 'defaults imap_login to email address' do
        post base_url, params: valid_migration_params, headers: headers, as: :json

        channel = Channel::Email.find(response.parsed_body['results'].first['channel_id'])
        expect(channel.imap_login).to eq('support@example.com')
      end

      it 'allows overriding imap settings' do
        params = {
          migrations: [
            {
              email: 'custom@example.com',
              provider: 'google',
              provider_config: google_provider_config,
              imap_address: 'custom.imap.server.com',
              imap_port: 143,
              imap_login: 'custom-login@example.com',
              imap_enable_ssl: false
            }
          ]
        }

        post base_url, params: params, headers: headers, as: :json

        channel = Channel::Email.find(response.parsed_body['results'].first['channel_id'])
        expect(channel.imap_address).to eq('custom.imap.server.com')
        expect(channel.imap_port).to eq(143)
        expect(channel.imap_login).to eq('custom-login@example.com')
        expect(channel.imap_enable_ssl).to be(false)
      end
    end

    context 'when migrating multiple channels' do
      around do |example|
        with_modified_env EMAIL_CHANNEL_MIGRATION: 'true' do
          example.run
        end
      end

      let(:bulk_params) do
        {
          migrations: [
            { email: 'first@example.com', provider: 'google', provider_config: google_provider_config },
            { email: 'second@example.com', provider: 'google', provider_config: google_provider_config },
            { email: 'third@example.com', provider: 'microsoft',
              provider_config: { access_token: 'test', refresh_token: 'test', expires_on: 1.hour.from_now.to_s } }
          ]
        }
      end

      it 'creates all channels and inboxes' do
        expect do
          post base_url, params: bulk_params, headers: headers, as: :json
        end.to change(Channel::Email, :count).by(3).and change(Inbox, :count).by(3)

        results = response.parsed_body['results']
        expect(results.map { |r| r['status'] }).to all(eq('success'))
        expect(results.map { |r| r['email'] }).to match_array(%w[first@example.com second@example.com third@example.com])
      end

      it 'continues processing when one migration fails' do
        create(:channel_email, email: 'first@example.com', account: account)

        expect do
          post base_url, params: bulk_params, headers: headers, as: :json
        end.to change(Channel::Email, :count).by(2).and change(Inbox, :count).by(2)

        results = response.parsed_body['results']
        failed = results.find { |r| r['email'] == 'first@example.com' }
        succeeded = results.reject { |r| r['email'] == 'first@example.com' }

        expect(failed['status']).to eq('error')
        expect(failed['message']).to include('Email has already been taken')
        expect(succeeded.map { |r| r['status'] }).to all(eq('success'))
      end
    end

    context 'when params are invalid' do
      around do |example|
        with_modified_env EMAIL_CHANNEL_MIGRATION: 'true' do
          example.run
        end
      end

      it 'returns unprocessable entity when migrations param is missing' do
        post base_url, params: {}, headers: headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable entity when migrations exceed max batch size' do
        params = {
          migrations: Array.new(26) { |i| { email: "user#{i}@example.com", provider: 'google', provider_config: google_provider_config } }
        }

        post base_url, params: params, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('Too many migrations')
      end

      it 'returns error for unsupported provider' do
        params = {
          migrations: [{ email: 'test@example.com', provider: 'Yahoo', provider_config: google_provider_config }]
        }

        post base_url, params: params, headers: headers, as: :json

        result = response.parsed_body['results'].first
        expect(result['status']).to eq('error')
        expect(result['message']).to include("Unsupported provider 'Yahoo'")
      end

      it 'returns error for duplicate email' do
        create(:channel_email, email: 'existing@example.com', account: account)

        params = {
          migrations: [{ email: 'existing@example.com', provider: 'google', provider_config: google_provider_config }]
        }

        post base_url, params: params, headers: headers, as: :json

        result = response.parsed_body['results'].first
        expect(result['status']).to eq('error')
        expect(result['message']).to include('Email has already been taken')
      end
    end
  end
end
