require 'rails_helper'

RSpec.describe Integrations::Moengage::HookBuilder do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe '#perform' do
    context 'with valid params' do
      let(:params) do
        {
          settings: {
            workspace_id: 'test-workspace',
            default_inbox_id: inbox.id,
            auto_create_contact: true,
            enable_ai_response: false
          }
        }
      end

      it 'creates a hook' do
        expect do
          described_class.new(account: account, params: params).perform
        end.to change(account.hooks, :count).by(1)
      end

      it 'sets the app_id to moengage' do
        hook = described_class.new(account: account, params: params).perform
        expect(hook.app_id).to eq('moengage')
      end

      it 'generates a webhook_token' do
        hook = described_class.new(account: account, params: params).perform
        expect(hook.settings['webhook_token']).to be_present
        expect(hook.settings['webhook_token'].length).to be > 20
      end

      it 'preserves the provided settings' do
        hook = described_class.new(account: account, params: params).perform
        expect(hook.settings['workspace_id']).to eq('test-workspace')
        expect(hook.settings['default_inbox_id']).to eq(inbox.id)
      end

      it 'sets hook status to enabled' do
        hook = described_class.new(account: account, params: params).perform
        expect(hook.status).to eq('enabled')
      end
    end

    context 'with AI response enabled' do
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:params) do
        {
          settings: {
            workspace_id: 'test-workspace',
            default_inbox_id: inbox.id,
            enable_ai_response: true,
            ai_agent_id: agent_bot.id
          }
        }
      end

      it 'creates a hook when agent bot is valid' do
        expect do
          described_class.new(account: account, params: params).perform
        end.to change(account.hooks, :count).by(1)
      end

      it 'raises error when agent bot is invalid' do
        params[:settings][:ai_agent_id] = 99_999

        expect do
          described_class.new(account: account, params: params).perform
        end.to raise_error(ArgumentError, 'Invalid AI agent')
      end
    end

    context 'with invalid params' do
      it 'raises error when workspace_id is missing' do
        params = { settings: { default_inbox_id: inbox.id } }

        expect do
          described_class.new(account: account, params: params).perform
        end.to raise_error(ArgumentError, 'Workspace ID is required')
      end

      it 'raises error when default_inbox_id is missing' do
        params = { settings: { workspace_id: 'test' } }

        expect do
          described_class.new(account: account, params: params).perform
        end.to raise_error(ArgumentError, 'Default inbox is required')
      end

      it 'raises error when inbox does not belong to account' do
        other_inbox = create(:inbox)
        params = { settings: { workspace_id: 'test', default_inbox_id: other_inbox.id } }

        expect do
          described_class.new(account: account, params: params).perform
        end.to raise_error(ArgumentError, 'Invalid inbox')
      end
    end
  end
end
