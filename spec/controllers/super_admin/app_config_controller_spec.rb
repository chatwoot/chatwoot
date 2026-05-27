require 'rails_helper'

RSpec.describe 'Super Admin Application Config API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/app_config'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:config) { InstallationConfig.find_or_initialize_by(name: 'FB_APP_ID').tap { |record| record.update!(value: 'TESTVALUE') } }

      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=facebook'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(config.value)
      end

      it 'groups Captain model and embedding settings' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=captain'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Captain Model')
        expect(response.body).to include('Embeddings and documents')
        expect(response.body).to include('Embedding Model')
        expect(response.body).to include('Custom (OpenAI-compatible)')
      end

      it 'includes RubyLLM API base defaults for the provider dropdown' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=captain'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('https://api.openai.com/v1')
        expect(response.body).to include('https://generativelanguage.googleapis.com/v1beta')
        expect(response.body).to include('https://openrouter.ai/api/v1')
      end

      it 'marks API Base as required when Provider is Custom' do
        set_installation_config('CAPTAIN_LLM_PROVIDER', 'custom')
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=captain'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('id="app_config_CAPTAIN_OPEN_AI_ENDPOINT"')
        expect(response.body).to include('required="required"')
        expect(response.body).to include('not /chat/completions')
      end

      it 'marks API Base as required when the selected provider needs one' do
        set_installation_config('CAPTAIN_LLM_PROVIDER', 'azure')
        set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=captain'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('id="app_config_CAPTAIN_OPEN_AI_ENDPOINT"')
        expect(response.body).to include('required="required"')
        expect(response.body).to include('API Base is required for the selected provider.')
      end

      it 'shows the OpenAI default hint when OpenAI API Base is blank' do
        set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
        set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=captain'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('API Base (optional)')
        expect(response.body).to include('Defaults to https://api.openai.com.')
      end
    end
  end

  describe 'POST /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        post '/super_admin/app_config', params: { app_config: { TESTKEY: 'TESTVALUE' } }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an aunthenticated super admin' do
      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=facebook', params: { app_config: { FB_APP_ID: 'FB_APP_ID' } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)
        expect(flash[:notice]).to be_present
        expect(flash[:alert]).to be_blank
        expect(flash[:success]).to be_blank

        config = GlobalConfig.get('FB_APP_ID')
        expect(config['FB_APP_ID']).to eq('FB_APP_ID')
      end

      it 'asks admins to restart web and worker processes for runtime config changes' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=captain', params: { app_config: { CAPTAIN_OPEN_AI_ENDPOINT: 'https://api.openai.com' } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)
        expect(flash[:success]).to be_present
        expect(flash[:alert]).to be_blank
        expect(flash[:notice]).to be_blank
      end

      it 'requires an API base for custom providers' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=captain', params: {
          app_config: {
            CAPTAIN_LLM_PROVIDER: 'custom',
            CAPTAIN_OPEN_AI_MODEL: 'accounts/fireworks/models/kimi-k2p6',
            CAPTAIN_OPEN_AI_ENDPOINT: ''
          }
        }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_app_config_path(config: 'captain'))
        expect(flash[:alert]).to eq('API Base is required when Provider is Custom')
      end

      it 'requires a model for custom providers' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=captain', params: {
          app_config: {
            CAPTAIN_LLM_PROVIDER: 'custom',
            CAPTAIN_OPEN_AI_MODEL: '',
            CAPTAIN_OPEN_AI_ENDPOINT: 'https://api.fireworks.ai/inference/v1'
          }
        }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_app_config_path(config: 'captain'))
        expect(flash[:alert]).to eq('Model is required when Provider is Custom')
      end

      it 'requires an API base for providers that need one' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=captain', params: {
          app_config: {
            CAPTAIN_LLM_PROVIDER: 'azure',
            CAPTAIN_OPEN_AI_MODEL: 'gpt-4.1',
            CAPTAIN_OPEN_AI_ENDPOINT: ''
          }
        }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_app_config_path(config: 'captain'))
        expect(flash[:alert]).to eq('API Base is required for the selected Provider')
      end

      it 'normalizes pasted chat completions URLs before saving' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=captain', params: {
          app_config: {
            CAPTAIN_LLM_PROVIDER: 'custom',
            CAPTAIN_OPEN_AI_MODEL: 'llama-3.3-70b-versatile',
            CAPTAIN_OPEN_AI_ENDPOINT: 'https://api.groq.com/openai/v1/chat/completions/'
          }
        }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)
        expect(InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').value).to eq('https://api.groq.com/openai/v1')
      end
    end
  end
end
