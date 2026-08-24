require 'rails_helper'

describe Integrations::Slack::HookBuilder do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex }
  let(:token) { SecureRandom.hex }
  let(:slack_access) do
    {
      'access_token' => token,
      'token_type' => 'bot',
      'scope' => 'channels:read,chat:write',
      'bot_user_id' => 'U012BOT',
      'team' => { 'id' => 'T012TEAM', 'name' => 'Support Workspace' }
    }
  end
  let(:identity) do
    {
      'ok' => true,
      'team' => 'Support Workspace',
      'team_id' => 'T012TEAM',
      'user_id' => 'U012BOT'
    }
  end

  describe '#perform' do
    before do
      oauth_client = instance_double(Slack::Web::Client, oauth_v2_access: slack_access)
      validation_client = instance_double(Slack::Web::Client, auth_test: identity)
      allow(Slack::Web::Client).to receive(:new).with(no_args).and_return(oauth_client)
      allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(validation_client)
    end

    it 'validates the token and stores non-secret workspace metadata' do
      builder = described_class.new(account: account, code: code)

      expect { builder.perform }.to change(account.hooks, :count).by(1)

      hook = account.hooks.last
      expect(hook.access_token).to eql(token)
      expect(hook).to be_disabled
      expect(hook.settings).to include(
        'scope' => 'channels:read,chat:write',
        'token_type' => 'bot',
        'workspace_id' => 'T012TEAM',
        'workspace_name' => 'Support Workspace',
        'bot_user_id' => 'U012BOT'
      )
      expect(hook.settings['validated_at']).to be_present
    end

    it 'upserts a catalog connection without changing the legacy channel status' do
      hook = create(
        :integrations_hook,
        account: account,
        app_id: 'slack',
        status: 'enabled',
        reference_id: 'C012LEGACY',
        settings: { channel_name: 'legacy-support' }
      )

      expect do
        described_class.new(account: account, code: code, catalog: true).perform
      end.not_to change(account.hooks, :count)

      expect(hook.reload).to be_enabled
      expect(hook.reference_id).to eq('C012LEGACY')
      expect(hook.settings).to include(
        'channel_name' => 'legacy-support',
        'catalog_connected' => true,
        'workspace_name' => 'Support Workspace'
      )
    end
  end
end
