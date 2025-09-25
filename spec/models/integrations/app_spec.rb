require 'rails_helper'

RSpec.describe Integrations::App do
  let(:apps) { described_class }
  let(:app) { apps.find(id: app_name) }
  let(:account) { create(:account) }

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

  describe '#action' do
    let(:app_name) { 'slack' }

    before do
      allow(Current).to receive(:account).and_return(account)
    end

    context 'when the app is slack' do
      it 'returns the action URL with client_id and redirect_uri' do
        with_modified_env SLACK_CLIENT_ID: 'dummy_client_id' do
          expect(app.action).to include('client_id=dummy_client_id')
          expect(app.action).to include(
            "/app/accounts/#{account.id}/settings/integrations/slack"
          )
        end
      end
    end

    context 'when the app is github' do
      let(:app_name) { 'github' }

      it 'returns the GitHub App installation URL with state parameter' do
        with_modified_env GITHUB_CLIENT_ID: 'dummy_client_id', GITHUB_APP_NAME: 'test-app' do
          expect(app.action).to include('https://github.com/apps/test-app/installations/new')
          expect(app.action).to include('state=')
        end
      end

      it 'uses default app name when GITHUB_APP_NAME is not set' do
        with_modified_env GITHUB_CLIENT_ID: 'dummy_client_id' do
          allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return('dummy_client_id')
          allow(GlobalConfigService).to receive(:load).with('GITHUB_APP_NAME', 'chatwoot-qa').and_return('chatwoot-qa')
          expect(app.action).to include('https://github.com/apps/chatwoot-qa/installations/new')
        end
      end
    end
  end

  describe '#active?' do
    let(:app_name) { 'slack' }

    context 'when the app is slack' do
      it 'returns true if SLACK_CLIENT_SECRET is present' do
        with_modified_env SLACK_CLIENT_SECRET: 'random_secret' do
          expect(app.active?(account)).to be true
        end
      end
    end

    context 'when the app is shopify' do
      let(:app_name) { 'shopify' }

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

    context 'when the app is github' do
      let(:app_name) { 'github' }

      it 'returns false if github credentials are not present' do
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return(nil)
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_SECRET', nil).and_return(nil)
        expect(app.active?(account)).to be false
      end

      it 'returns false if only client_id is present' do
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return('client_id')
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_SECRET', nil).and_return(nil)
        expect(app.active?(account)).to be false
      end

      it 'returns false if only client_secret is present' do
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return(nil)
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_SECRET', nil).and_return('client_secret')
        expect(app.active?(account)).to be false
      end

      it 'returns true if both client_id and client_secret are present' do
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return('client_id')
        allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_SECRET', nil).and_return('client_secret')
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
  end
end
