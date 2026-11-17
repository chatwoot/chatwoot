require 'rails_helper'

RSpec.describe 'WhatsApp Session Providers API', type: :request do
  let(:account) { create(:account) }
  let(:url) { "/api/v1/accounts/#{account.id}/whatsapp/session_providers" }

  describe 'GET /api/v1/accounts/{account.id}/whatsapp/session_providers' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        get url, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      def payload
        get url, headers: administrator.create_new_auth_token, as: :json
        response.parsed_body['payload']
      end

      it 'describes every session provider and no cloud one' do
        expect(payload.pluck('key')).to contain_exactly('native', 'uazapi', 'baileys', 'zapi')
      end

      it 'carries the form and the capabilities the dashboard renders from' do
        uazapi = payload.find { |p| p['key'] == 'uazapi' }

        expect(uazapi['fields'].pluck('name')).to include('base_url', 'token')
        expect(uazapi['fields'].find { |f| f['name'] == 'token' }).to include('required' => true, 'secret' => true)
        expect(uazapi['capabilities']).to include('reactions')
        expect(uazapi['pairing_modes']).to contain_exactly('qr', 'code')
      end

      it 'tells the form which fields go behind the advanced options' do
        advanced = payload.to_h { |p| [p['key'], p['fields'].select { |f| f['advanced'] }.pluck('name')] }

        expect(advanced['native']).to contain_exactly('proxy_url', 'mark_as_read', 'presence_subscribe', 'history_sync')
        expect(advanced['uazapi']).to contain_exactly('mark_as_read', 'presence_subscribe', 'history_sync')
        expect(payload.flat_map { |p| p['fields'] }).to all(include('advanced' => be(true).or(be(false))))
      end

      it 'tells the picker which providers are still in beta' do
        expect(payload.select { |p| p['beta'] }.pluck('key')).to contain_exactly('uazapi')
      end

      it 'marks a provider creatable until the account turns it off' do
        expect(payload.find { |p| p['key'] == 'uazapi' }['creatable']).to be(true)

        account.update!(whatsapp_uazapi_disabled: true)

        expect(payload.find { |p| p['key'] == 'uazapi' }['creatable']).to be(false)
      end

      # `native` answers to two gates set by different people: the deployment serves it
      # unless it turned the connector off, and an account has it unless it was withdrawn.
      describe 'the two gates on native' do
        let(:native) { payload.find { |p| p['key'] == 'native' } }
        let(:prefix) { "watest#{SecureRandom.hex(4)}:" }
        let(:redis) { Redis.new(Redis::Config.app) }

        around do |example|
          with_modified_env(WHATSAPP_CONNECTOR_REDIS_PREFIX: prefix) { example.run }
          keys = redis.keys("#{prefix}*")
          redis.del(*keys) if keys.any?
        end

        def connector_running
          redis.hset("#{prefix}instance:one", 'protocol_min', '1', 'protocol_max', '1')
          redis.sadd("#{prefix}instances", 'one')
        end

        it 'offers it to every account of an installation that did not turn it off' do
          connector_running

          with_modified_env WHATSAPP_CONNECTOR_ENABLED: nil do
            expect(native).to include('available' => true, 'creatable' => true)
            expect(native).not_to have_key('unavailable_reason')
          end
        end

        # On by default is not the same as started: the Docker image runs the connector next
        # to Sidekiq, and an installation from source has nothing that does. An inbox created
        # with nobody to pair it would never connect.
        it 'keeps it uncreatable while no connector is running, and says so' do
          with_modified_env WHATSAPP_CONNECTOR_ENABLED: nil do
            expect(native).to include('available' => true, 'creatable' => false,
                                      'unavailable_reason' => 'connector_not_running', 'unavailable_detail' => nil)
          end
        end

        it 'carries the reason the newest failed start published' do
          # listed in the opposite order of their times, so the order of the keys decides nothing
          { 'a-worker' => ['connector exited (status 1)', '2026-11-17T10:00:00Z'],
            'b-worker' => ['schema whatsapp_connector does not exist', '2026-11-17T11:00:00Z'] }.each do |id, (error, at)|
            redis.set("#{prefix}embedded:#{id}", { error: error, at: at }.to_json)
            redis.zadd("#{prefix}embedded", Time.now.to_i + 120, id)
          end

          with_modified_env WHATSAPP_CONNECTOR_ENABLED: nil do
            expect(native['unavailable_detail']).to eq('schema whatsapp_connector does not exist')
          end
        end

        it 'keeps it uncreatable while the connector is turned off, whatever the account says' do
          with_modified_env WHATSAPP_CONNECTOR_ENABLED: 'false' do
            expect(native).to include('available' => false, 'creatable' => false)
            expect(native).not_to have_key('unavailable_reason')
          end
        end

        it 'keeps it uncreatable for the account it was withdrawn from' do
          connector_running
          account.update!(whatsapp_native_disabled: true)

          with_modified_env WHATSAPP_CONNECTOR_ENABLED: nil do
            expect(native).to include('available' => true, 'creatable' => false)
          end
        end

        it 'gives no reason to an account it was withdrawn from, so the picker leaves it out' do
          account.update!(whatsapp_native_disabled: true)

          with_modified_env WHATSAPP_CONNECTOR_ENABLED: nil do
            expect(native).not_to have_key('unavailable_reason')
          end
        end
      end

      # Frozen, not withdrawn: they are what most inboxes run on today, and the
      # deprecation is what stops offering them.
      context 'when the installation has a Baileys API connected' do
        before do
          stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', 'http://baileys.test')
          stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', 'key')
          stub_request(:get, 'http://baileys.test/status').to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
        end

        it 'keeps the legacy providers on offer' do
          legacy = payload.select { |p| p['legacy'] }

          expect(legacy.pluck('key')).to contain_exactly('baileys', 'zapi')
          expect(legacy.pluck('creatable')).to all(be(true))
        end

        it 'withdraws the legacy providers when the deprecation switch is thrown' do
          with_modified_env WHATSAPP_LEGACY_PROVIDERS_CREATABLE: 'false' do
            expect(payload.select { |p| p['legacy'] }.pluck('creatable')).to all(be(false))
          end
        end
      end

      # Baileys is a separate API the installation points at. Where none is connected
      # there is nothing to offer, and the rest of the catalog is unaffected.
      describe 'the Baileys installation gate' do
        let(:baileys) { payload.find { |p| p['key'] == 'baileys' } }
        let(:zapi) { payload.find { |p| p['key'] == 'zapi' } }

        it 'leaves Baileys out when no Baileys API is configured' do
          stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', nil)

          expect(baileys['creatable']).to be(false)
          expect(zapi['creatable']).to be(true)
        end

        it 'leaves Baileys out when the configured Baileys API does not answer' do
          stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', 'http://baileys.test')
          stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_API_KEY', 'key')
          stub_request(:get, 'http://baileys.test/status').to_return(status: 503)

          expect(baileys['creatable']).to be(false)
        end

        it 'still describes Baileys, so an existing inbox keeps its label and capabilities' do
          stub_const('Whatsapp::Providers::WhatsappBaileysService::DEFAULT_URL', nil)

          expect(baileys).to include('legacy' => true)
          expect(baileys['capabilities']).to include('qr_pairing')
        end
      end
    end
  end
end
