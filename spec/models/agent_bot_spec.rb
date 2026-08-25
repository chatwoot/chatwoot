require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_shared.rb'
require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe AgentBot do
  describe 'associations' do
    it { is_expected.to have_many(:agent_bot_inboxes) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_many(:platform_app_permissibles) }
  end

  describe 'concerns' do
    it_behaves_like 'access_tokenable'
    it_behaves_like 'avatarable'
  end

  context 'when it validates outgoing_url length' do
    let(:agent_bot) { create(:agent_bot) }

    it 'valid when within limit' do
      agent_bot.outgoing_url = 'a' * Limits::URL_LENGTH_LIMIT
      expect(agent_bot.valid?).to be true
    end

    it 'invalid when crossed the limit' do
      agent_bot.outgoing_url = 'a' * (Limits::URL_LENGTH_LIMIT + 1)
      agent_bot.valid?
      expect(agent_bot.errors[:outgoing_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
    end
  end

  context 'when agent bot is deleted' do
    let(:agent_bot) { create(:agent_bot) }
    let(:message) { create(:message, sender: agent_bot) }

    it 'nullifies the message sender key' do
      expect(message.sender).to eq agent_bot
      agent_bot.destroy!

      expect(message.reload.sender).to be_nil
    end

    it 'destroys associated platform_app_permissibles' do
      platform_app = create(:platform_app)
      create(:platform_app_permissible, platform_app: platform_app, permissible: agent_bot)

      expect { agent_bot.destroy! }.to change(PlatformAppPermissible, :count).by(-1)
    end
  end

  describe 'when a Pathors agent bot is destroyed' do
    let(:account) { create(:account) }
    let(:pathors_url) { 'https://backend.pathors.test/project/project-uuid-1/integration/chatwoot/callback' }

    it 'tells Pathors the integration is disconnected' do
      agent_bot = create(:agent_bot, account: account, outgoing_url: pathors_url)

      expect { agent_bot.destroy! }.to have_enqueued_job(AgentBots::WebhookJob).with(
        pathors_url,
        { event: 'integration.disconnected', account_id: account.id },
        :agent_bot_webhook,
        secret: agent_bot.secret
      )
    end

    it 'stays silent for a bot pointing somewhere else' do
      agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://example.com/webhook')

      expect { agent_bot.destroy! }.not_to have_enqueued_job(AgentBots::WebhookJob)
    end

    it 'removes the account OAuth hook so the integration card resets', :aggregate_failures do
      agent_bot = create(:agent_bot, account: account, outgoing_url: pathors_url)
      create(:integrations_hook, :pathors, account: account)

      expect { agent_bot.destroy! }.to change { account.hooks.where(app_id: 'pathors').count }.from(1).to(0)
      expect(AgentBots::WebhookJob).to have_been_enqueued.exactly(:once)
    end

    it 'leaves the hooks of other integrations alone' do
      agent_bot = create(:agent_bot, account: account, outgoing_url: pathors_url)
      create(:integrations_hook, account: account)

      expect { agent_bot.destroy! }.not_to(change { account.hooks.where(app_id: 'slack').count })
    end

    it 'leaves the hooks of other accounts alone' do
      agent_bot = create(:agent_bot, account: account, outgoing_url: pathors_url)
      other_hook = create(:integrations_hook, :pathors, account: create(:account))

      agent_bot.destroy!

      expect(Integrations::Hook.exists?(other_hook.id)).to be true
    end

    it 'keeps the hook when the destroyed bot is not a Pathors bot' do
      agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://example.com/webhook')
      create(:integrations_hook, :pathors, account: account)

      expect { agent_bot.destroy! }.not_to(change { account.hooks.where(app_id: 'pathors').count })
    end

    it 'completes the destroy even when the hook cannot be removed', :aggregate_failures do
      agent_bot = create(:agent_bot, account: account, outgoing_url: pathors_url)
      create(:integrations_hook, :pathors, account: account)
      allow_any_instance_of(Integrations::Hook).to receive(:destroy).and_raise(StandardError, 'boom') # rubocop:disable RSpec/AnyInstance

      expect { agent_bot.destroy! }.not_to raise_error
      expect(described_class.exists?(agent_bot.id)).to be false
    end
  end

  describe '#system_bot?' do
    context 'when account_id is nil' do
      let(:agent_bot) { create(:agent_bot, account_id: nil) }

      it 'returns true' do
        expect(agent_bot.system_bot?).to be true
      end
    end

    context 'when account_id is present' do
      let(:account) { create(:account) }
      let(:agent_bot) { create(:agent_bot, account: account) }

      it 'returns false' do
        expect(agent_bot.system_bot?).to be false
      end
    end
  end
end
