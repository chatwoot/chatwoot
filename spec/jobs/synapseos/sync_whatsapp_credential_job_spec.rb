require 'rails_helper'

RSpec.describe Synapseos::SyncWhatsappCredentialJob do
  let(:account) { create(:account, custom_attributes: { 'synapseos_agentic_slug' => 'royal_enfield' }) }
  let(:agentic_client) { instance_double(Synapseos::AgenticClient) }

  before do
    allow(Synapseos::Agentic).to receive(:config).and_return(enabled: true)
    allow(Synapseos::Agentic).to receive(:client).and_return(agentic_client)

    avisa_client = instance_double(Whatsapp::Providers::AvisaClient, register_webhook: true)
    allow(Whatsapp::Providers::AvisaClient).to receive(:new).and_return(avisa_client)
  end

  around do |example|
    with_modified_env(FRONTEND_URL: 'http://localhost:3000') { example.run }
  end

  def success_result(credential_id: 'cred_123', credential_name: 'Avisa +5511999990000')
    Synapseos::AgenticClient::Result.success('credential_id' => credential_id, 'credential_name' => credential_name)
  end

  def failure_result(kind, message, details: nil)
    Synapseos::AgenticClient::Result.failure(kind, message, details: details)
  end

  describe '#perform' do
    it 'returns silently when channel does not exist' do
      expect(agentic_client).not_to receive(:sync_whatsapp_credential)
      described_class.new.perform(0)
    end

    it 'no-ops when agentic is disabled' do
      allow(Synapseos::Agentic).to receive(:config).and_return(enabled: false)
      channel = create(:channel_whatsapp, account: account, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      expect(agentic_client).not_to receive(:sync_whatsapp_credential)
      described_class.new.perform(channel.id)
    end

    it 'no-ops when account has no agentic slug' do
      acc = create(:account)
      channel = create(:channel_whatsapp, account: acc, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      expect(agentic_client).not_to receive(:sync_whatsapp_credential)
      described_class.new.perform(channel.id)
    end

    it 'no-ops for unsupported provider' do
      channel = create(:channel_whatsapp, account: account, provider: 'default',
                                          provider_config: { 'api_key' => 'k' },
                                          validate_provider_config: false, sync_templates: false)
      expect(agentic_client).not_to receive(:sync_whatsapp_credential)
      described_class.new.perform(channel.id)
    end

    it 'syncs avisa credential and writes back credential_id' do
      channel = create(:channel_whatsapp, account: account, provider: 'avisa', phone_number: '+5511990000000',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      expected_payload = { provider: 'avisa', token: 'avisa_key', name: 'Avisa +5511990000000' }
      expect(agentic_client).to receive(:sync_whatsapp_credential)
        .with('royal_enfield', expected_payload).and_return(success_result(credential_id: 'cred_avisa'))

      described_class.new.perform(channel.id)
      expect(channel.reload.provider_config['synapseos_credential_id']).to eq('cred_avisa')
    end

    it 'preserves concurrent provider_config edits made during the HTTP window' do
      channel = create(:channel_whatsapp, account: account, provider: 'avisa', phone_number: '+5511990000000',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)

      # Simulate a user editing provider_config in another process while the
      # job's HTTP roundtrip is in flight: write directly to the DB so the
      # in-memory `channel` AR object held by the job is now stale.
      allow(agentic_client).to receive(:sync_whatsapp_credential) do
        Channel::Whatsapp.where(id: channel.id).update_all( # rubocop:disable Rails/SkipsModelValidations
          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br',
                             'external_user_field' => 'concurrent' }
        )
        success_result(credential_id: 'cred_avisa')
      end

      described_class.new.perform(channel.id)

      reloaded = channel.reload.provider_config
      expect(reloaded['external_user_field']).to eq('concurrent')
      expect(reloaded['synapseos_credential_id']).to eq('cred_avisa')
    end

    it 'includes phone_number_id and business_account_id for whatsapp_cloud' do
      # NOTE: factory merges defaults into whatsapp_cloud provider_config, so
      # we pre-stub directly to bypass that hardcoded merge.
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', phone_number: '+5511990000001',
                                          provider_config: { 'source' => 'embedded_signup' },
                                          validate_provider_config: false, sync_templates: false)
      channel.update_column(:provider_config, { 'api_key' => 'waba_key', 'phone_number_id' => 'phn_1', # rubocop:disable Rails/SkipsModelValidations
                                                'business_account_id' => 'wba_1' })

      expected_payload = { provider: 'waba', token: 'waba_key', name: 'WABA +5511990000001',
                           phone_number_id: 'phn_1', business_account_id: 'wba_1' }
      expect(agentic_client).to receive(:sync_whatsapp_credential)
        .with('royal_enfield', expected_payload).and_return(success_result(credential_id: 'cred_waba'))

      described_class.new.perform(channel.id)
      expect(channel.reload.provider_config['synapseos_credential_id']).to eq('cred_waba')
    end

    it 'sends shared_secret for hyperflow (no token)' do
      channel = create(:channel_whatsapp, account: account, provider: 'hyperflow', phone_number: '+5511990000002',
                                          provider_config: { 'shared_secret' => 'hyper_sec', 'outgoing_url' => 'https://n8n.test' },
                                          validate_provider_config: false, sync_templates: false)
      expected_payload = { provider: 'hyperflow', shared_secret: 'hyper_sec', name: 'Hyperflow +5511990000002' }
      expect(agentic_client).to receive(:sync_whatsapp_credential)
        .with('royal_enfield', expected_payload).and_return(success_result(credential_id: 'cred_hyper'))

      described_class.new.perform(channel.id)
      expect(channel.reload.provider_config['synapseos_credential_id']).to eq('cred_hyper')
    end

    it 'raises TransientError on agentic_offline so ActiveJob retries' do
      channel = create(:channel_whatsapp, account: account, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      allow(agentic_client).to receive(:sync_whatsapp_credential)
        .and_return(failure_result(:agentic_offline, 'connection refused'))

      expect { described_class.new.perform(channel.id) }
        .to raise_error(Synapseos::SyncWhatsappCredentialJob::TransientError, /connection refused/)
    end

    it 'does not raise on validation failure and logs an error' do
      channel = create(:channel_whatsapp, account: account, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      allow(agentic_client).to receive(:sync_whatsapp_credential)
        .and_return(failure_result(:validation, 'Validation error', details: { 'detail' => 'bad token' }))

      expect(Rails.logger).to receive(:error).with(/credential_sync_failed.*validation/)
      expect { described_class.new.perform(channel.id) }.not_to raise_error
      expect(channel.reload.provider_config['synapseos_credential_id']).to be_nil
    end

    it 'no-ops the audit write when the log model is not loaded (PR5 not yet merged)' do
      channel = create(:channel_whatsapp, account: account, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      allow(agentic_client).to receive(:sync_whatsapp_credential)
        .and_return(failure_result(:unauthorized, 'Invalid credentials'))

      expect(Rails.logger).to receive(:error)
      expect { described_class.new.perform(channel.id) }.not_to raise_error
    end
  end
end
