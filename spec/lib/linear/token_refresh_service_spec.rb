require 'rails_helper'

describe Linear::TokenRefreshService do
  let(:access_token) { 'valid_access_token' }
  let(:refresh_token) { 'valid_refresh_token' }
  let(:expires_at) { 20.days.from_now.iso8601 }
  let(:settings) do
    {
      token_type: 'Bearer',
      expires_in: 3600,
      scope: 'read,write',
      refresh_token: refresh_token,
      expires_at: expires_at
    }
  end
  let(:hook) do
    hook_double = instance_double(Integrations::Hook, access_token: access_token, updated_at: 2.days.ago)
    allow(hook_double).to receive(:settings).and_return(settings)
    hook_double
  end
  let(:service) { described_class.new(hook) }

  describe '#token' do
    context 'when hook is nil' do
      let(:service) { described_class.new(nil) }

      it 'returns nil access_token' do
        expect(service.token).to be_nil
      end
    end

    context 'when hook has no refresh token' do
      let(:settings) { { token_type: 'Bearer' } }
      let(:hook) do
        hook_double = instance_double(Integrations::Hook, access_token: access_token, updated_at: 2.days.ago)
        allow(hook_double).to receive(:settings).and_return(settings)
        hook_double
      end

      it 'attempts migration and returns access token' do
        expect(service).to receive(:migrate_old_token).and_return(true)
        expect(service.token).to eq(access_token)
      end
    end

    context 'when token is eligible for refresh' do
      let(:expires_at) { 5.days.from_now.iso8601 }

      it 'refreshes the token and returns access token' do
        expect(service).to receive(:refresh_access_token).and_return(true)
        expect(service.token).to eq(access_token)
      end
    end

    context 'when token is not eligible for refresh' do
      it 'returns the current access token' do
        expect(service.token).to eq(access_token)
      end
    end
  end

  describe '#refresh_access_token' do
    let(:token_url) { 'https://api.linear.app/oauth/token' }
    let(:refresh_response) do
      {
        'access_token' => 'new_access_token',
        'refresh_token' => 'new_refresh_token',
        'token_type' => 'Bearer',
        'expires_in' => 3600,
        'scope' => 'read,write'
      }
    end

    context 'when refresh token is present' do
      before do
        allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_ID', nil).and_return('client_id')
        allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return('client_secret')
      end

      context 'when refresh is successful' do
        before do
          stub_request(:post, token_url)
            .with(
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
              body: {
                grant_type: 'refresh_token',
                refresh_token: refresh_token,
                client_id: 'client_id',
                client_secret: 'client_secret'
              }
            )
            .to_return(
              status: 200,
              body: refresh_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'updates tokens and returns true' do
          expect(service).to receive(:update_tokens).with(refresh_response)
          expect(service.refresh_access_token).to be(true)
        end
      end

      context 'when refresh fails' do
        before do
          stub_request(:post, token_url)
            .to_return(status: 400, body: { error: 'invalid_grant' }.to_json)
        end

        it 'logs error and returns false' do
          expect(Rails.logger).to receive(:error).with(match(/Linear token refresh failed/))
          expect(service.refresh_access_token).to be(false)
        end
      end
    end

    context 'when refresh token is missing' do
      let(:settings) { { token_type: 'Bearer' } }

      it 'returns false' do
        expect(service.refresh_access_token).to be(false)
      end
    end
  end

  describe '#migrate_old_token' do
    let(:migrate_url) { 'https://api.linear.app/oauth/migrate_old_token' }
    let(:migrate_response) do
      {
        'access_token' => 'new_access_token',
        'refresh_token' => 'new_refresh_token',
        'token_type' => 'Bearer',
        'expires_in' => 3600,
        'scope' => 'read,write'
      }
    end

    context 'when migration is successful' do
      before do
        stub_request(:post, migrate_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: migrate_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'updates tokens and returns true' do
        expect(service).to receive(:update_tokens).with(migrate_response)
        expect(service.migrate_old_token).to be(true)
      end
    end

    context 'when migration fails' do
      before do
        stub_request(:post, migrate_url)
          .to_return(status: 400, body: { error: 'invalid_token' }.to_json)
      end

      it 'logs error and returns false' do
        expect(Rails.logger).to receive(:error).with(match(/Linear token migration failed/))
        expect(service.migrate_old_token).to be(false)
      end
    end
  end

  describe '#token_eligible_for_refresh?' do
    context 'when token data is missing' do
      let(:settings) { {} }

      it 'returns false' do
        expect(service.send(:token_eligible_for_refresh?)).to be(false)
      end
    end

    context 'when all conditions are met' do
      let(:expires_at) { 5.days.from_now.iso8601 }

      it 'returns true' do
        expect(service.send(:token_eligible_for_refresh?)).to be(true)
      end
    end

    context 'when token is expired' do
      let(:expires_at) { 1.day.ago.iso8601 }

      it 'returns false' do
        expect(service.send(:token_eligible_for_refresh?)).to be(false)
      end
    end

    context 'when token was updated recently' do
      let(:expires_at) { 5.days.from_now.iso8601 }
      let(:hook) do
        instance_double(
          Integrations::Hook,
          access_token: access_token,
          settings: settings,
          updated_at: 1.hour.ago
        )
      end

      it 'returns false' do
        expect(service.send(:token_eligible_for_refresh?)).to be(false)
      end
    end

    context 'when token is not approaching expiry' do
      let(:expires_at) { 30.days.from_now.iso8601 }

      it 'returns false' do
        expect(service.send(:token_eligible_for_refresh?)).to be(false)
      end
    end
  end

  describe '#refresh_token?' do
    context 'when refresh token is present' do
      it 'returns true' do
        expect(service.send(:refresh_token?)).to be(true)
      end
    end

    context 'when refresh token is missing' do
      let(:settings) { { token_type: 'Bearer' } }

      it 'returns false' do
        expect(service.send(:refresh_token?)).to be(false)
      end
    end
  end

  describe 'private methods' do
    describe '#update_tokens' do
      let(:response_data) do
        {
          'access_token' => 'new_access_token',
          'refresh_token' => 'new_refresh_token',
          'token_type' => 'Bearer',
          'expires_in' => 3600,
          'scope' => 'read,write'
        }
      end
      let(:expected_expires_at) { (3600.seconds.from_now).iso8601 }

      before do
        allow(Time).to receive(:current).and_return(Time.parse('2025-01-01 12:00:00 UTC'))
      end

      it 'updates the hook with new token data' do
        expect(hook).to receive(:update!).with(
          access_token: 'new_access_token',
          settings: settings.merge(
            token_type: 'Bearer',
            expires_in: 3600,
            scope: 'read,write',
            refresh_token: 'new_refresh_token',
            expires_at: expected_expires_at
          )
        )

        service.send(:update_tokens, response_data)
      end
    end

    describe '#calculate_expires_at' do
      before do
        allow(Time).to receive(:current).and_return(Time.parse('2025-01-01 12:00:00 UTC'))
      end

      it 'calculates expiry time as ISO8601 string' do
        result = service.send(:calculate_expires_at, 3600)
        expect(result).to eq('2025-01-01T13:00:00Z')
      end

      it 'returns nil when expires_in is nil' do
        result = service.send(:calculate_expires_at, nil)
        expect(result).to be_nil
      end
    end
  end
end
