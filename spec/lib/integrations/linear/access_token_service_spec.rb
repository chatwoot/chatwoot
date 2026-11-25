require 'rails_helper'

describe Integrations::Linear::AccessTokenService do
  let(:account) { create(:account) }
  let(:client_id) { 'linear_client_id' }
  let(:client_secret) { 'linear_client_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
  end

  describe '#access_token' do
    context 'when access token is still valid' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'valid_access_token',
          settings: {
            refresh_token: 'refresh_token',
            token_type: 'Bearer',
            scope: 'read,write',
            expires_on: 30.minutes.from_now.utc.to_s
          }
        )
      end

      it 'returns the current access token' do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, 'https://api.linear.app/oauth/migrate_old_token')
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('valid_access_token')
        expect(WebMock).not_to have_requested(:post, 'https://api.linear.app/oauth/token')
        expect(WebMock).not_to have_requested(:post, 'https://api.linear.app/oauth/migrate_old_token')
      end
    end

    context 'when access token is expired and refresh token is present' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'expired_access_token',
          settings: {
            refresh_token: 'old_refresh_token',
            token_type: 'Bearer',
            scope: 'read,write',
            expires_on: 1.hour.ago.utc.to_s
          }
        )
      end

      it 'refreshes the token and persists new values' do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: {
              access_token: 'new_access_token',
              refresh_token: 'new_refresh_token',
              token_type: 'Bearer',
              expires_in: 7200,
              scope: 'read,write'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('new_access_token')
        hook.reload
        expect(hook.access_token).to eq('new_access_token')
        expect(hook.settings['refresh_token']).to eq('new_refresh_token')
        expect(hook.settings['expires_in']).to eq(7200)
        expect(hook.settings['expires_on']).to be_present
      end

      it 'falls back to latest persisted token on refresh failure' do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(status: 401, body: { error: 'invalid_grant' }.to_json, headers: { 'Content-Type' => 'application/json' })

        Integrations::Hook.find(hook.id).update!(access_token: 'rotated_access_token')

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('rotated_access_token')
      end

      it 'does not overwrite the existing token on malformed success response' do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: {
              refresh_token: 'new_refresh_token',
              token_type: 'Bearer',
              expires_in: 7200,
              scope: 'read,write'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('expired_access_token')
        hook.reload
        expect(hook.access_token).to eq('expired_access_token')
        expect(hook.settings['refresh_token']).to eq('old_refresh_token')
      end
    end

    context 'when refresh token is missing and legacy migration is applicable' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'legacy_access_token',
          settings: {
            token_type: 'Bearer',
            scope: 'read,write'
          }
        )
      end

      it 'migrates the legacy token and persists refresh token data' do
        stub_request(:post, 'https://api.linear.app/oauth/migrate_old_token')
          .to_return(
            status: 200,
            body: {
              access_token: 'migrated_access_token',
              refresh_token: 'migrated_refresh_token',
              token_type: 'Bearer',
              expires_in: 7200,
              scope: 'read,write'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('migrated_access_token')
        hook.reload
        expect(hook.access_token).to eq('migrated_access_token')
        expect(hook.settings['refresh_token']).to eq('migrated_refresh_token')
        expect(hook.settings['expires_in']).to eq(7200)
        expect(hook.settings['expires_on']).to be_present
      end

      it 'does not overwrite the existing token on malformed migration success response' do
        stub_request(:post, 'https://api.linear.app/oauth/migrate_old_token')
          .to_return(
            status: 200,
            body: {
              refresh_token: 'migrated_refresh_token',
              token_type: 'Bearer',
              expires_in: 7200,
              scope: 'read,write'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('legacy_access_token')
        hook.reload
        expect(hook.access_token).to eq('legacy_access_token')
        expect(hook.settings['token_type']).to eq('Bearer')
      end
    end

    context 'when another writer lands on the hook settings during the token call' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'old_access_token',
          settings: {
            refresh_token: 'refresh_token',
            token_type: 'Bearer',
            expires_on: 1.minute.from_now.utc.to_s
          }
        )
      end

      before do
        stub_request(:post, 'https://api.linear.app/oauth/token').to_return do
          # O outro escritor e a API publica de hooks (`PATCH .../integrations/hooks/:id`, que
          # aceita `settings` como hash aberto). Gravado direto na linha porque a copia que o
          # servico vai escrever de volta foi lida antes desta chamada.
          Integrations::Hook.where(id: hook.id)
                            .update_all("settings = settings || '{\"project_id\":\"ENG\"}'::jsonb")  # rubocop:disable Rails/SkipsModelValidations
          {
            status: 200,
            body: { access_token: 'new_access_token', refresh_token: 'new_refresh_token', expires_in: 3600 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          }
        end
      end

      it 'keeps the key that landed while Linear was answering' do
        described_class.new(hook: hook).access_token

        expect(hook.reload.settings['project_id']).to eq('ENG')
      end

      it 'still writes the token it went to fetch' do
        described_class.new(hook: hook).access_token

        expect(hook.reload.access_token).to eq('new_access_token')
        expect(hook.reload.settings['refresh_token']).to eq('new_refresh_token')
      end

      # The merge is taken on a separate row object, so this object still holds the old token until
      # it is read again, and the callers return `hook.access_token`.
      it 'hands the caller the token it just persisted' do
        expect(described_class.new(hook: hook).access_token).to eq('new_access_token')
      end
    end

    # Same shape, other axis, and the one the merge cannot reach: the writer that lands during the
    # POST is an OAuth reconnection, so it writes the very keys this refresh is about to write. Its
    # tokens are the live ones, because the admin just authorised them, and the refresh is holding a
    # pair derived from a refresh token the row no longer has. Writing it back undoes the
    # reconnection and leaves the integration on a token Linear has already invalidated.
    context 'when an OAuth reconnection lands on the hook during the token call' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'old_access_token',
          settings: {
            refresh_token: 'refresh_token',
            token_type: 'Bearer',
            expires_on: 1.minute.from_now.utc.to_s
          }
        )
      end

      before do
        allow(Rails.logger).to receive(:warn)
        stub_request(:post, 'https://api.linear.app/oauth/token').to_return do
          # `Linear::CallbacksController#handle_response`: the admin reconnected, so the row gets a
          # new access token in its column and a new refresh token in its settings. Through its own
          # AR object, which is what the controller does, and `access_token` is an encrypted column,
          # so a raw UPDATE would write something the reader cannot decrypt.
          reconnected = Integrations::Hook.find(hook.id)
          reconnected.access_token = 'reconnected_access_token'
          reconnected.settings = reconnected.settings.merge('refresh_token' => 'reconnected_refresh_token')
          reconnected.save!
          {
            status: 200,
            body: { access_token: 'new_access_token', refresh_token: 'new_refresh_token', expires_in: 3600 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          }
        end
      end

      it 'does not undo the reconnection' do
        described_class.new(hook: hook).access_token

        expect(hook.reload.access_token).to eq('reconnected_access_token')
        expect(hook.reload.settings['refresh_token']).to eq('reconnected_refresh_token')
      end

      it 'hands the caller the token that is in the row' do
        expect(described_class.new(hook: hook).access_token).to eq('reconnected_access_token')
      end

      it 'says the rotation it spent was not stored' do
        described_class.new(hook: hook).access_token

        expect(Rails.logger).to have_received(:warn).with(/refresh token this call spent/)
      end
    end

    context 'when the response leaves out the keys the hook already has' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'old_access_token',
          settings: {
            refresh_token: 'refresh_token',
            token_type: 'Bearer',
            scope: 'read,write',
            expires_on: 1.minute.from_now.utc.to_s
          }
        )
      end

      before do
        stub_request(:post, 'https://api.linear.app/oauth/token').to_return(
          status: 200,
          body: { access_token: 'new_access_token' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'leaves the stored scope standing rather than writing nil over it' do
        described_class.new(hook: hook).access_token

        expect(hook.reload.settings['scope']).to eq('read,write')
      end

      # No `expires_in` in the response means the expiry this service can speak about did not
      # change, so it writes nothing there. Rewriting it from the copy read before the call is how
      # an expiry set during the call would be undone.
      it 'does not rewrite the expiry it was not told about' do
        stored = hook.settings['expires_on']
        Integrations::Hook.where(id: hook.id)
                          .update_all("settings = settings || '{\"expires_on\":\"2030-01-01 00:00:00 UTC\"}'::jsonb") # rubocop:disable Rails/SkipsModelValidations

        described_class.new(hook: hook).access_token

        expect(hook.reload.settings['expires_on']).to eq('2030-01-01 00:00:00 UTC')
        expect(hook.reload.settings['expires_on']).not_to eq(stored)
      end
    end
  end
end
