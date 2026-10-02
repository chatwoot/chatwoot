require 'rails_helper'

RSpec.describe 'Enterprise Super Admin Captain application config', type: :request do
  let(:super_admin) { create(:super_admin) }

  before do
    allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
    sign_in(super_admin, scope: :super_admin)
  end

  it 'includes the Context.dev key and web crawling provider in Captain settings' do
    controller = SuperAdmin::AppConfigsController.new

    expect(controller.send(:captain_config_options)).to include('CONTEXT_DEV_API_KEY', 'WEB_CRAWLING_PROVIDER')
  end

  it 'warns when Context.dev is selected without an API key' do
    post '/super_admin/app_config?config=captain', params: {
      app_config: { WEB_CRAWLING_PROVIDER: 'context_dev', CONTEXT_DEV_API_KEY: '' }
    }

    expect(flash[:alert]).to eq('Context.dev API key must be configured before selecting it as the web crawling provider')
    expect(InstallationConfig.find_by(name: 'WEB_CRAWLING_PROVIDER')).to be_nil
  end

  it 'warns when the selected Context.dev key is cleared' do
    create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: 'context-key')

    post '/super_admin/app_config?config=captain', params: {
      app_config: { WEB_CRAWLING_PROVIDER: 'context_dev', CONTEXT_DEV_API_KEY: '' }
    }

    expect(flash[:alert]).to be_present
    expect(InstallationConfig.find_by(name: 'CONTEXT_DEV_API_KEY').value).to eq('context-key')
  end

  it 'accepts a Context.dev key submitted with the provider selection' do
    post '/super_admin/app_config?config=captain', params: {
      app_config: { CONTEXT_DEV_API_KEY: 'context-key', WEB_CRAWLING_PROVIDER: 'context_dev' }
    }

    expect(flash[:alert]).to be_blank
    expect(InstallationConfig.find_by(name: 'WEB_CRAWLING_PROVIDER').value).to eq('context_dev')
    expect(InstallationConfig.find_by(name: 'CONTEXT_DEV_API_KEY').value).to eq('context-key')
  end
end
