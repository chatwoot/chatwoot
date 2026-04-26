require 'rails_helper'

RSpec.describe Synapseos::ChatwootMirror do
  let(:account) { create(:account, name: 'Old Name') }
  let(:base_yaml) do
    {
      'slug' => 'royal_enfield',
      'name' => 'Royal Enfield',
      'chatwoot_account_id' => account.id,
      'persona_full' => 'Natália',
      'agents' => {
        'natalia' => { 'enabled' => true, 'persona_full' => 'Natália', 'persona_short' => 'Nat' },
        'otto' => { 'enabled' => true, 'persona_full' => 'Otto', 'persona_short' => 'Otto' },
        'iza' => { 'enabled' => false }
      },
      'whatsapp' => {
        'provider' => 'avisa',
        'phone_number' => '+551199990000',
        'avisa' => { 'base_url' => 'https://www.avisaapi.com.br' }
      }
    }
  end

  before do
    # Stub the Avisa upstream client so the after_create webhook registration
    # doesn't issue real HTTP calls. FRONTEND_URL is provided by the around
    # block; provider_config/sync_templates checks are skipped via factory
    # transient flags on the create(:channel_whatsapp) calls below.
    avisa_client = instance_double(Whatsapp::Providers::AvisaClient, register_webhook: true)
    allow(Whatsapp::Providers::AvisaClient).to receive(:new).and_return(avisa_client)
  end

  around do |example|
    with_modified_env(FRONTEND_URL: 'http://localhost:3000') { example.run }
  end

  describe '#sync_account_from_yaml' do
    it 'updates name and stores agentic slug pointer in custom_attributes' do
      described_class.new(account: account, client_yaml: base_yaml).sync_account_from_yaml
      account.reload
      expect(account.name).to eq('Royal Enfield')
      expect(account.custom_attributes['synapseos_agentic_slug']).to eq('royal_enfield')
      expect(account.custom_attributes['synapseos_agentic_account_id']).to eq(account.id)
    end

    it 'is idempotent when already in sync' do
      described_class.new(account: account, client_yaml: base_yaml).sync_account_from_yaml
      account.reload
      svc = described_class.new(account: account, client_yaml: base_yaml)
      svc.sync_account_from_yaml
      noop = svc.instance_variable_get(:@actions).find { |a| a[:kind] == :account_unchanged }
      expect(noop).to be_present
    end
  end

  describe '#sync_agent_bots' do
    # NOTE: Account#after_create seeds the canonical 7-role squadron via
    # Synapseos::SquadronBotsSeeder. The mirror is therefore an upsert layer
    # on top of those seeded rows — for enabled YAML agents it adopts/updates
    # the existing row, and creates rows for new roles like `natalia`.
    it 'creates/updates AgentBots for enabled YAML agents (idempotent over auto-seeded squadron)' do
      described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots
      bots = AgentBot.where(account_id: account.id)
      expect(bots.find_by(squadron_role: 'natalia')).to be_present
      expect(bots.find_by(squadron_role: 'natalia').name).to eq('Natália')
      expect(bots.find_by(squadron_role: 'otto').description).to eq('Synapse OS — Otto')
      expect(bots.find_by(squadron_role: 'otto').name).to eq('Otto')
    end

    it 'is idempotent on a second run' do
      described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots
      expect { described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots }
        .not_to change(AgentBot, :count)
    end

    it 'updates name when persona_full changes in YAML' do
      described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots
      bot = AgentBot.find_by(account_id: account.id, squadron_role: 'natalia')
      expect(bot.name).to eq('Natália')

      new_yaml = base_yaml.deep_dup
      new_yaml['agents']['natalia']['persona_full'] = 'Nat (vendas)'
      described_class.new(account: account, client_yaml: new_yaml).sync_agent_bots
      expect(bot.reload.name).to eq('Nat (vendas)')
    end

    it 'does NOT delete bots when removed from YAML, soft-disables instead' do
      described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots
      otto = AgentBot.find_by(account_id: account.id, squadron_role: 'otto')

      yaml_without_otto = base_yaml.deep_dup
      yaml_without_otto['agents']['otto']['enabled'] = false

      svc = described_class.new(account: account, client_yaml: yaml_without_otto)
      expect { svc.sync_agent_bots }.not_to change(AgentBot, :count)

      expect(otto.reload.synapseos_disabled?).to be true
      drift_action = svc.instance_variable_get(:@actions).find { |a| a[:kind] == :agent_bot_disabled }
      expect(drift_action).to be_present
      expect(drift_action[:status]).to eq(:drift)
    end

    it 're-enables a previously soft-disabled bot when YAML re-adds it' do
      described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots
      yaml_without = base_yaml.deep_dup
      yaml_without['agents']['otto']['enabled'] = false
      described_class.new(account: account, client_yaml: yaml_without).sync_agent_bots
      otto = AgentBot.find_by(account_id: account.id, squadron_role: 'otto')
      expect(otto.synapseos_disabled?).to be true

      described_class.new(account: account, client_yaml: base_yaml).sync_agent_bots
      expect(otto.reload.synapseos_disabled?).to be false
    end
  end

  describe '#sync_inbox' do
    it 'no-ops when YAML has no whatsapp block' do
      yaml = base_yaml.deep_dup.tap { |y| y.delete('whatsapp') }
      svc = described_class.new(account: account, client_yaml: yaml)
      svc.sync_inbox
      action = svc.instance_variable_get(:@actions).first
      expect(action[:kind]).to eq(:inbox_skipped)
      expect(action[:status]).to eq(:noop)
    end

    it 'returns :inbox_missing when no matching channel exists' do
      svc = described_class.new(account: account, client_yaml: base_yaml)
      svc.sync_inbox
      action = svc.instance_variable_get(:@actions).first
      expect(action[:kind]).to eq(:inbox_missing)
      expect(action[:status]).to eq(:drift)
      expect(action[:suggested_fix]).to include('Settings → Inboxes wizard')
    end

    it 'flags credential mismatch without overwriting existing inbox config' do
      channel = create(:channel_whatsapp,
                       account: account,
                       phone_number: '+551199990000',
                       provider: 'avisa',
                       provider_config: { 'api_key' => 'avisa_secret', 'base_url' => 'https://old.example.com' },
                       sync_templates: false,
                       validate_provider_config: false)

      svc = described_class.new(account: account, client_yaml: base_yaml)
      svc.sync_inbox

      action = svc.instance_variable_get(:@actions).first
      expect(action[:kind]).to eq(:inbox_credential_mismatch)
      expect(action[:status]).to eq(:drift)
      # original config preserved
      expect(channel.reload.provider_config['base_url']).to eq('https://old.example.com')
    end

    it 'reports :inbox_in_sync when provider_config matches YAML' do
      create(:channel_whatsapp,
             account: account,
             phone_number: '+551199990000',
             provider: 'avisa',
             provider_config: { 'api_key' => 'avisa_secret', 'base_url' => 'https://www.avisaapi.com.br' },
             sync_templates: false,
             validate_provider_config: false)

      svc = described_class.new(account: account, client_yaml: base_yaml)
      svc.sync_inbox
      action = svc.instance_variable_get(:@actions).first
      expect(action[:kind]).to eq(:inbox_in_sync)
    end
  end

  describe '#detect_drift' do
    it 'reports :no_whatsapp_config_in_yaml when whatsapp section missing' do
      yaml = base_yaml.deep_dup.tap { |y| y.delete('whatsapp') }
      drift = described_class.new(account: account, client_yaml: yaml).detect_drift
      expect(drift.map { |d| d[:kind] }).to include(:no_whatsapp_config_in_yaml)
    end

    it 'reports account_name_mismatch, agent_bot_missing and inbox_missing for an empty account' do
      drift = described_class.new(account: account, client_yaml: base_yaml).detect_drift
      kinds = drift.map { |d| d[:kind] }
      expect(kinds).to include(:account_name_mismatch)
      expect(kinds).to include(:agent_bot_missing)
      expect(kinds).to include(:inbox_missing)
    end

    it 'reports :agent_bot_orphan for enabled bots not in YAML (read-only)' do
      # Account#after_create seeds the 7-role squadron; YAML only enables
      # `natalia` and `otto`, so the other 6 are orphans relative to YAML.
      yaml = base_yaml.deep_dup
      drift = described_class.new(account: account, client_yaml: yaml).detect_drift
      orphans = drift.select { |d| d[:kind] == :agent_bot_orphan }
      expect(orphans.map { |d| d[:message] }.join(' ')).to include('vitor')
      # detect_drift must NOT mutate (still 7 active, none soft-disabled)
      expect(AgentBot.where(account_id: account.id).count).to eq(7)
    end
  end

  describe '#sync_all' do
    it 'wraps sync_* calls in a transaction and rolls back on failure' do
      previous_name = account.name # 'Old Name' from let
      bot_count_before = AgentBot.where(account_id: account.id).count

      svc = described_class.new(account: account, client_yaml: base_yaml)
      allow(svc).to receive(:sync_inbox).and_raise(StandardError, 'boom from inbox')

      result = svc.sync_all
      expect(result.ok?).to be false
      expect(result.errors.first[:kind]).to eq(:transaction_failed)
      expect(result.errors.first[:message]).to eq('boom from inbox')
      # Account name change inside the transaction must be rolled back
      expect(account.reload.name).to eq(previous_name)
      # No new AgentBots created (natalia would have been added by sync_agent_bots)
      expect(AgentBot.where(account_id: account.id).count).to eq(bot_count_before)
      expect(AgentBot.exists?(account_id: account.id, squadron_role: 'natalia')).to be false
    end

    it 'returns ok=true with collected actions on happy path' do
      result = described_class.new(account: account, client_yaml: base_yaml).sync_all
      expect(result.ok?).to be true
      kinds = result.actions.map { |a| a[:kind] }
      expect(kinds).to include(:account_updated)
      expect(kinds).to include(:agent_bot_synced)
      expect(kinds).to include(:inbox_missing)
    end
  end
end
