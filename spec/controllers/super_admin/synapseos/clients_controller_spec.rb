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
end
