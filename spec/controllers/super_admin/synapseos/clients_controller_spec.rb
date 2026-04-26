require 'rails_helper'

RSpec.describe 'Super Admin Synapseos clients', type: :request do
  before(:all) do
    # The super_admin layout depends on a built vite-test manifest. These specs
    # focus on controller behaviour, so render without the layout.
    SuperAdmin::Synapseos::ClientsController.layout(false)
  end

  let(:super_admin) { create(:super_admin) }
  let(:base_url) { 'http://agentic.test' }
  let(:user) { 'admin' }
  let(:password) { 'secret' }
  let(:basic_auth_header) { "Basic #{Base64.strict_encode64("#{user}:#{password}")}" }

  def install_config(name, value)
    config = InstallationConfig.find_or_initialize_by(name: name)
    config.locked = false
    config.value = value
    config.save!
    config
  end

  def configure_agentic!
    install_config('SYNAPSEOS_AGENTIC_URL', base_url)
    install_config('SYNAPSEOS_AGENTIC_USER', user)
    install_config('SYNAPSEOS_AGENTIC_PASSWORD', password)
    install_config('SYNAPSEOS_AGENTIC_ENABLED', 'true')
    GlobalConfig.clear_cache
    Synapseos::Agentic.reset!
  end

  before do
    Synapseos::Agentic.reset!
  end

  after do
    Synapseos::Agentic.reset!
  end

  describe 'GET /super_admin/synapseos/clients' do
    context 'when not authenticated' do
      it 'redirects to login' do
        get '/super_admin/synapseos/clients'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when agentic is not configured' do
      it 'renders the not_configured partial' do
        with_modified_env SYNAPSEOS_AGENTIC_URL: nil, SYNAPSEOS_AGENTIC_USER: nil,
                          SYNAPSEOS_AGENTIC_PASSWORD: nil, SYNAPSEOS_AGENTIC_ENABLED: nil do
          sign_in(super_admin, scope: :super_admin)
          get '/super_admin/synapseos/clients'

          expect(response).to have_http_status(:success)
          expect(response.body).to include('Configure agentic')
        end
      end
    end

    context 'when agentic is configured' do
      before { configure_agentic! }

      it 'renders the list with mocked clients response' do
        clients_payload = [
          {
            slug: 'acme', name: 'Acme', status: 'deployed', deployed: true,
            chatwoot_account_id: 7,
            agents: { 'sales' => { 'enabled' => true }, 'support' => { 'enabled' => false } }
          }
        ]
        templates_payload = {
          'agents' => {
            'sales' => { 'display_name' => 'Sales Agent', 'status' => 'available' },
            'support' => { 'display_name' => 'Support Agent', 'status' => 'planned' }
          }
        }

        stub_request(:get, "#{base_url}/api/clients")
          .with(headers: { 'Authorization' => basic_auth_header })
          .to_return(status: 200, body: clients_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, "#{base_url}/api/templates")
          .with(headers: { 'Authorization' => basic_auth_header })
          .to_return(status: 200, body: templates_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('acme')
        expect(response.body).to include('Acme')
        expect(response.body).to include('Account #7')
        expect(response.body).to include('deployed')
        expect(response.body).to include('Sales Agent')
        expect(response.body).not_to include('Support Agent')
      end

      it 'handles :agentic_offline gracefully without 500' do
        stub_request(:get, "#{base_url}/api/clients")
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('The agentic panel is offline')
      end

      it 'handles :unauthorized with friendly error' do
        stub_request(:get, "#{base_url}/api/clients")
          .to_return(status: 401, body: { detail: 'bad creds' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Invalid credentials')
      end
    end
  end

  describe 'GET /super_admin/synapseos/clients/:slug' do
    context 'when agentic is configured' do
      before { configure_agentic! }

      it 'renders 404 when client not found' do
        stub_request(:get, "#{base_url}/api/clients/missing")
          .to_return(status: 404, body: { detail: 'not found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/missing'

        expect(response).to have_http_status(:not_found)
      end

      it 'redirects to index with alert when agentic is offline' do
        stub_request(:get, "#{base_url}/api/clients/acme")
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/acme'

        expect(response).to redirect_to(super_admin_synapseos_clients_path)
        expect(flash[:alert]).to include('The agentic panel is offline')
      end

      it 'renders successfully with full client data' do
        client_payload = {
          slug: 'acme', name: 'Acme', full_name: 'Acme Corp', persona_full: 'helpful agent',
          persona_short: 'helpful', dealer_name: 'Acme Dealer', city: 'SP',
          chatwoot_account_id: 7, deployed: true, status: 'deployed',
          agents: { 'sales' => { 'enabled' => true } },
          workflows: { 'sales' => ['wf-123'] },
          whatsapp: { 'provider' => 'avisa', 'credential' => 'avisa-acme' }
        }
        templates_payload = {
          'agents' => { 'sales' => { 'display_name' => 'Sales Agent', 'status' => 'available' } }
        }

        stub_request(:get, "#{base_url}/api/clients/acme")
          .to_return(status: 200, body: client_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, "#{base_url}/api/templates")
          .to_return(status: 200, body: templates_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/acme'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Acme Corp')
        expect(response.body).to include('avisa')
      end
    end

    context 'when agentic is not configured' do
      it 'renders the not_configured partial' do
        with_modified_env SYNAPSEOS_AGENTIC_URL: nil, SYNAPSEOS_AGENTIC_USER: nil,
                          SYNAPSEOS_AGENTIC_PASSWORD: nil, SYNAPSEOS_AGENTIC_ENABLED: nil do
          sign_in(super_admin, scope: :super_admin)
          get '/super_admin/synapseos/clients/anything'

          expect(response).to have_http_status(:success)
          expect(response.body).to include('Configure agentic')
        end
      end
    end
  end

  describe 'CRUD actions (Fase 2.2)' do
    let(:schema_payload) do
      {
        'type' => 'object',
        'properties' => {
          'slug' => { 'type' => 'string', 'title' => 'Slug' },
          'name' => { 'type' => 'string', 'title' => 'Name' },
          'chatwoot_account_id' => { 'type' => 'integer', 'title' => 'Chatwoot account' },
          'credentials' => {
            'type' => 'object',
            'properties' => {
              'postgres' => {
                'type' => 'object',
                'properties' => {
                  'id' => { 'type' => 'string' },
                  'name' => { 'type' => 'string' }
                }
              }
            }
          }
        },
        'required' => %w[slug name]
      }
    end
    let(:templates_payload) { { 'agents' => { 'sales' => { 'display_name' => 'Sales' } } } }
    let(:credentials_payload) { [{ 'id' => 'cred-1', 'name' => 'Postgres prod', 'type' => 'postgres' }] }

    def stub_form_metadata
      stub_request(:get, "#{base_url}/api/schema")
        .to_return(status: 200, body: schema_payload.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/api/templates")
        .to_return(status: 200, body: templates_payload.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, "#{base_url}/api/n8n/credentials")
        .to_return(status: 200, body: credentials_payload.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    before { configure_agentic! }

    describe 'GET /super_admin/synapseos/clients/new' do
      it 'renders the form with templates/credentials/schema fetched' do
        stub_form_metadata

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/new'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Slug')
        expect(response.body).to include('Postgres prod')
      end
    end

    describe 'POST /super_admin/synapseos/clients' do
      it 'creates the client, writes audit row, and redirects to show on success' do
        stub_form_metadata
        stub_request(:put, "#{base_url}/api/clients/acme")
          .to_return(status: 200, body: { slug: 'acme', name: 'Acme' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          post '/super_admin/synapseos/clients',
               params: { slug: 'acme', client: { slug: 'acme', name: 'Acme', chatwoot_account_id: '7' } }
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        log = SynapseosAgenticDeploymentLog.last
        expect(log.action).to eq('create')
        expect(log.status).to eq('success')
        expect(log.slug).to eq('acme')
        expect(log.account_id).to eq(7)
      end

      it 'does not crash when client params are missing entirely' do
        stub_form_metadata
        stub_request(:put, %r{#{base_url}/api/clients/.*})
          .to_return(status: 422, body: { detail: [{ loc: %w[body slug], msg: 'field required' }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/synapseos/clients'

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Slug')
      end

      it 'flattens 422 validation errors and re-renders new' do
        stub_form_metadata
        validation_body = {
          detail: [
            { loc: %w[body credentials postgres id], msg: 'field required', type: 'value_error.missing' }
          ]
        }
        stub_request(:put, "#{base_url}/api/clients/acme")
          .to_return(status: 422, body: validation_body.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/synapseos/clients',
             params: { slug: 'acme', client: { slug: 'acme', name: 'Acme' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('credentials.postgres.id')
        expect(response.body).to include('field required')

        log = SynapseosAgenticDeploymentLog.last
        expect(log.status).to eq('failure')
      end
    end

    describe 'PATCH /super_admin/synapseos/clients/:slug' do
      it 'updates the client, writes audit row, and redirects to show' do
        stub_form_metadata
        stub_request(:put, "#{base_url}/api/clients/acme")
          .to_return(status: 200, body: { slug: 'acme', name: 'Acme v2' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          patch '/super_admin/synapseos/clients/acme',
                params: { client: { slug: 'acme', name: 'Acme v2', chatwoot_account_id: '7' } }
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        expect(SynapseosAgenticDeploymentLog.last.action).to eq('update')
      end

      it 'does not crash when client params are missing entirely' do
        stub_form_metadata
        stub_request(:put, "#{base_url}/api/clients/acme")
          .to_return(status: 422, body: { detail: [{ loc: %w[body name], msg: 'field required' }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        patch '/super_admin/synapseos/clients/acme'

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Edit acme')
      end
    end

    describe 'DELETE /super_admin/synapseos/clients/:slug' do
      it 'deletes the client, writes audit row, and redirects to index' do
        stub_request(:delete, "#{base_url}/api/clients/acme")
          .to_return(status: 200, body: { ok: true }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          delete '/super_admin/synapseos/clients/acme'
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_clients_path)
        expect(SynapseosAgenticDeploymentLog.last.action).to eq('delete')
      end

      it 'flashes a friendly error and redirects to show on 409 conflict' do
        stub_request(:delete, "#{base_url}/api/clients/acme")
          .to_return(status: 409, body: { detail: 'still deployed' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        delete '/super_admin/synapseos/clients/acme'

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        expect(flash[:error]).to include('deployed')
      end
    end

    describe '#build_payload_from_params' do
      let(:controller_instance) { SuperAdmin::Synapseos::ClientsController.new }

      it 'zips __keys__ / __values__ pairs into a flat hash and strips blanks' do
        input = { 'extra_placeholders' => { '__keys__' => %w[foo bar], '__values__' => %w[1 2] } }
        result = controller_instance.send(:build_payload_from_params, input)
        expect(result).to eq('extra_placeholders' => { 'foo' => '1', 'bar' => '2' })
      end

      it 'coerces booleans and integers' do
        input = { 'agents' => { 'sales' => { 'enabled' => 'true', 'priority' => '5' } } }
        result = controller_instance.send(:build_payload_from_params, input)
        expect(result).to eq('agents' => { 'sales' => { 'enabled' => true, 'priority' => 5 } })
      end
    end
  end

  describe 'Deploy / undeploy / build / status / snapshots / restore (Fase 2.3)' do
    before { configure_agentic! }

    describe 'POST /super_admin/synapseos/clients/:slug/deploy' do
      it 'happy path: calls deploy, audits success, redirects with poll flash' do
        deploy_response = { 'slug' => 'acme', 'agents_workflows' => { 'sales' => ['wf-1'] }, 'status' => 'deployed' }
        stub_request(:post, "#{base_url}/api/clients/acme/deploy")
          .to_return(status: 200, body: deploy_response.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          post '/super_admin/synapseos/clients/acme/deploy'
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        expect(flash[:notice]).to include('Deploy iniciado')
        expect(flash[:poll_status]).to be(true)

        log = SynapseosAgenticDeploymentLog.last
        expect(log.action).to eq('deploy')
        expect(log.status).to eq('success')
        expect(log.slug).to eq('acme')
      end

      it 'agentic_offline: audits failure and flashes error' do
        stub_request(:post, "#{base_url}/api/clients/acme/deploy")
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))

        sign_in(super_admin, scope: :super_admin)

        expect do
          post '/super_admin/synapseos/clients/acme/deploy'
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        expect(flash[:error]).to include('Falhou')

        log = SynapseosAgenticDeploymentLog.last
        expect(log.action).to eq('deploy')
        expect(log.status).to eq('failure')
      end
    end

    describe 'POST /super_admin/synapseos/clients/:slug/undeploy' do
      it 'happy path: calls undeploy, audits success, redirects' do
        stub_request(:post, "#{base_url}/api/clients/acme/undeploy")
          .to_return(status: 200, body: { slug: 'acme', removed: %w[wf-1 wf-2] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          post '/super_admin/synapseos/clients/acme/undeploy'
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        expect(SynapseosAgenticDeploymentLog.last.action).to eq('undeploy')
        expect(SynapseosAgenticDeploymentLog.last.status).to eq('success')
      end
    end

    describe 'POST /super_admin/synapseos/clients/:slug/build' do
      it 'happy path: calls build, audits success, flashes' do
        build_response = { slug: 'acme', path: '/tmp/build', files: ['a.json', 'b.json'] }
        stub_request(:post, "#{base_url}/api/clients/acme/build")
          .to_return(status: 200, body: build_response.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          post '/super_admin/synapseos/clients/acme/build'
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(super_admin_synapseos_client_path(slug: 'acme'))
        expect(flash[:notice]).to include('Build')

        log = SynapseosAgenticDeploymentLog.last
        expect(log.action).to eq('build')
        expect(log.status).to eq('success')
      end
    end

    describe 'GET /super_admin/synapseos/clients/:slug/status' do
      it 'returns JSON with status and deployed flag' do
        client_payload = { 'slug' => 'acme', 'status' => 'deployed', 'deployed' => true,
                           'workflows' => { 'sales' => ['wf-1'] } }
        stub_request(:get, "#{base_url}/api/clients/acme")
          .to_return(status: 200, body: client_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/acme/status', as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['status']).to eq('deployed')
        expect(body['deployed']).to be(true)
        expect(body['workflows']).to eq('sales' => ['wf-1'])
      end

      it 'returns 502 with error message when agentic is offline' do
        stub_request(:get, "#{base_url}/api/clients/acme")
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/acme/status', as: :json

        expect(response).to have_http_status(:bad_gateway)
        body = response.parsed_body
        expect(body['status']).to eq('error')
      end
    end

    describe 'GET /super_admin/synapseos/clients/:slug/snapshots' do
      let(:snapshots_payload) do
        [
          { 'id' => '20260424-120000', 'ts' => '2026-04-24T12:00:00Z', 'size' => 2048 },
          { 'id' => '20260423-100000', 'ts' => '2026-04-23T10:00:00Z', 'size' => 1024 }
        ]
      end

      it 'JSON returns the array of snapshots' do
        stub_request(:get, "#{base_url}/api/clients/acme/snapshots")
          .to_return(status: 200, body: snapshots_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/acme/snapshots', as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body.length).to eq(2)
        expect(body.first['id']).to eq('20260424-120000')
      end

      it 'HTML renders the history view' do
        stub_request(:get, "#{base_url}/api/clients/acme/snapshots")
          .to_return(status: 200, body: snapshots_payload.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/synapseos/clients/acme/snapshots'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('20260424-120000')
        expect(response.body).to include('Snapshots')
      end
    end

    describe 'POST /super_admin/synapseos/clients/:slug/restore_snapshot' do
      it 'audits the action and redirects to history tab on success' do
        stub_request(:post, "#{base_url}/api/clients/acme/snapshots/20260424-120000/restore")
          .to_return(status: 200, body: { slug: 'acme' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)

        expect do
          post '/super_admin/synapseos/clients/acme/restore_snapshot',
               params: { snapshot_id: '20260424-120000' }
        end.to change(SynapseosAgenticDeploymentLog, :count).by(1)

        expect(response).to redirect_to(
          super_admin_synapseos_client_path(slug: 'acme', tab: 'history')
        )

        log = SynapseosAgenticDeploymentLog.last
        expect(log.action).to eq('restore_snapshot')
        expect(log.status).to eq('success')
        expect(log.payload).to eq('snapshot_id' => '20260424-120000')
      end

      it 'flashes an error and redirects when restore fails' do
        stub_request(:post, "#{base_url}/api/clients/acme/snapshots/bad/restore")
          .to_return(status: 404, body: { detail: 'snapshot not found' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/synapseos/clients/acme/restore_snapshot',
             params: { snapshot_id: 'bad' }

        expect(response).to redirect_to(
          super_admin_synapseos_client_path(slug: 'acme', tab: 'history')
        )
        expect(flash[:error]).to include('Restore falhou')
        expect(SynapseosAgenticDeploymentLog.last.status).to eq('failure')
      end
    end
  end
end
