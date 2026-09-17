require 'rails_helper'

RSpec.describe Integrations::App do
  let(:apps) { described_class }
  let(:app) { apps.find(id: app_name) }
  let(:account) { create(:account) }

  before { allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true) }

  describe '#name' do
    let(:app_name) { 'slack' }

    it 'returns the name' do
      expect(app.name).to eq('Slack')
    end
  end

  describe '#logo' do
    let(:app_name) { 'slack' }

    it 'returns the logo' do
      expect(app.logo).to eq('slack.png')
    end
  end

  describe '#visible_properties' do
    context 'when the app has visible properties' do
      let(:app_name) { 'dialogflow' }

      it 'returns the configured property names as strings' do
        expect(app.visible_properties).to contain_exactly('project_id', 'region', 'language_code')
      end
    end

    context 'when the app has no visible properties configured' do
      let(:app_name) { 'webhook' }

      it 'defaults to an empty list' do
        expect(app.visible_properties).to eq([])
      end
    end
  end

  describe '#action' do
    let(:app_name) { 'slack' }

    before do
      allow(Current).to receive(:account).and_return(account)
    end

    context 'when the app is slack' do
      it 'returns the action URL with client_id and redirect_uri' do
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_ID', nil).and_return('dummy_client_id')

        expect(app.action).to include('client_id=dummy_client_id')
        expect(app.action).to include(
          "/app/accounts/#{account.id}/settings/integrations/slack"
        )
      end
    end

    context 'when the app is shopify' do
      let(:app_name) { 'shopify' }

      before do
        account.enable_features('shopify_integration')
        allow(GlobalConfigService).to receive(:load)
          .with('SHOPIFY_APP_STORE_URL', nil)
          .and_return('https://apps.shopify.com/chatwoot')
      end

      it 'returns the App Store URL when both feature gates are enabled' do
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(true)

        expect(app.action).to eq('https://apps.shopify.com/chatwoot')
      end

      it 'does not return an action when the installation switch is disabled' do
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(false)

        expect(app.action).to be_nil
      end
    end
  end

  describe '#active?' do
    let(:app_name) { 'slack' }

    context 'when the app is slack' do
      it 'returns true if SLACK_CLIENT_SECRET is present' do
        allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_SECRET', nil).and_return('random_secret')

        expect(app.active?(account)).to be true
      end
    end

    context 'when the app is shopify' do
      let(:app_name) { 'shopify' }

      before do
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(true)
      end

      it 'returns true if the shopify integration feature is enabled' do
        account.enable_features('shopify_integration')
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('client_id')
        expect(app.active?(account)).to be true
      end

      it 'returns false if the shopify integration feature is disabled' do
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('client_id')
        expect(app.active?(account)).to be false
      end

      it 'returns false if SHOPIFY_CLIENT_ID is not present, even if feature is enabled' do
        account.enable_features('shopify_integration')
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return(nil)
        expect(app.active?(account)).to be false
      end

      it 'returns false if the installation switch is disabled' do
        account.enable_features('shopify_integration')
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(false)
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('client_id')

        expect(app.active?(account)).to be false
      end
    end

    context 'when the app is linear' do
      let(:app_name) { 'linear' }

      it 'returns false if the linear integration feature is disabled' do
        expect(app.active?(account)).to be false
      end

      it 'returns true if the linear integration feature is enabled' do
        account.enable_features('linear_integration')
        account.save!
        allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_ID', nil).and_return('client_id')
        expect(app.active?(account)).to be true
      end
    end

    context 'when other apps are queried' do
      let(:app_name) { 'webhook' }

      it 'returns true' do
        expect(app.active?(account)).to be true
      end
    end
  end

  describe '#enabled?' do
    context 'when the app is webhook' do
      let(:app_name) { 'webhook' }

      it 'returns false if the account does not have any webhooks' do
        expect(app.enabled?(account)).to be false
      end

      it 'returns true if the account has webhooks' do
        create(:webhook, account: account)
        expect(app.enabled?(account)).to be true
      end
    end

    context 'when the app is anything other than webhook' do
      let(:app_name) { 'openai' }

      it 'returns false if the account does not have any hooks for the app' do
        expect(app.enabled?(account)).to be false
      end

      it 'returns true if the account has hooks for the app' do
        create(:integrations_hook, :openai, account: account)
        expect(app.enabled?(account)).to be true
      end
    end

    context 'when the app is shopify' do
      let(:app_name) { 'shopify' }

      before { account.enable_features!('shopify_integration') }

      it 'returns true when the Shopify hook is enabled' do
        create(:integrations_hook, :shopify, account: account, status: :enabled)

        expect(app.enabled?(account)).to be true
      end

      it 'returns false when the retained Shopify hook is disabled' do
        create(:integrations_hook, :shopify, account: account, status: :disabled)

        expect(app.enabled?(account)).to be false
      end
    end
  end
end
