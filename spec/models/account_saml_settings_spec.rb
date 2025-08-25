# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountSamlSettings, type: :model do
  let(:account) { create(:account) }
  let(:saml_settings) { build(:account_saml_settings, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    context 'when enabled is false' do
      it 'does not require sso_url, certificate, or sp_entity_id' do
        settings = build(:account_saml_settings, account: account, enabled: false)
        expect(settings).to be_valid
      end
    end

    context 'when enabled is true' do
      it 'requires sso_url' do
        settings = build(:account_saml_settings, account: account, enabled: true, sso_url: nil)
        expect(settings).not_to be_valid
        expect(settings.errors[:sso_url]).to include("can't be blank")
      end

      it 'requires certificate' do
        settings = build(:account_saml_settings, account: account, enabled: true, certificate: nil)
        expect(settings).not_to be_valid
        expect(settings.errors[:certificate]).to include("can't be blank")
      end

      it 'requires sp_entity_id' do
        settings = build(:account_saml_settings, account: account, enabled: true, sp_entity_id: nil)
        expect(settings).not_to be_valid
        expect(settings.errors[:sp_entity_id]).to include("can't be blank")
      end
    end
  end

  describe '#generate_certificate_fingerprint' do
    context 'when certificate is valid' do
      it 'generates SHA256 fingerprint automatically on save' do
        settings = create(:account_saml_settings, account: account)
        expect(settings.certificate_fingerprint).to be_present
        expect(settings.certificate_fingerprint).to match(/\A[0-9A-F]{2}(:[0-9A-F]{2}){31}\z/)
      end

      it 'regenerates fingerprint when certificate changes' do
        settings = create(:account_saml_settings, account: account)
        original_fingerprint = settings.certificate_fingerprint

        # Generate a new certificate
        key = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 2 # Different serial number
        cert.subject = OpenSSL::X509::Name.parse('/C=US/ST=Test/L=Test/O=Test/CN=different.example.com')
        cert.issuer = cert.subject
        cert.public_key = key.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + (365 * 24 * 60 * 60)
        cert.sign(key, OpenSSL::Digest.new('SHA256'))
        new_cert = cert.to_pem

        settings.update!(certificate: new_cert)

        expect(settings.certificate_fingerprint).not_to eq(original_fingerprint)
        expect(settings.certificate_fingerprint).to be_present
      end

      it 'does not regenerate fingerprint when other fields change' do
        settings = create(:account_saml_settings, account: account)
        original_fingerprint = settings.certificate_fingerprint

        settings.update!(sso_url: 'https://new.example.com/sso')

        expect(settings.certificate_fingerprint).to eq(original_fingerprint)
      end
    end

    context 'when certificate is invalid' do
      it 'adds error and prevents save' do
        settings = build(:account_saml_settings, account: account, certificate: 'invalid certificate')
        expect(settings.save).to be_falsey
        expect(settings.errors[:certificate]).to include('is not a valid X.509 certificate')
      end

      it 'handles empty certificate gracefully' do
        settings = build(:account_saml_settings, account: account, certificate: '', certificate_fingerprint: nil)
        settings.save(validate: false)
        expect(settings.certificate_fingerprint).to be_nil
      end
    end
  end

  describe '#saml_enabled?' do
    it 'returns true when enabled and required fields are present' do
      settings = build(:account_saml_settings,
                       account: account,
                       enabled: true,
                       sso_url: 'https://example.com/sso',
                       certificate_fingerprint: 'AA:BB:CC')
      expect(settings.saml_enabled?).to be true
    end

    it 'returns false when not enabled' do
      settings = build(:account_saml_settings,
                       account: account,
                       enabled: false,
                       sso_url: 'https://example.com/sso',
                       certificate_fingerprint: 'AA:BB:CC')
      expect(settings.saml_enabled?).to be false
    end

    it 'returns false when sso_url is missing' do
      settings = build(:account_saml_settings,
                       account: account,
                       enabled: true,
                       sso_url: nil,
                       certificate_fingerprint: 'AA:BB:CC')
      expect(settings.saml_enabled?).to be false
    end

    it 'returns false when certificate_fingerprint is missing' do
      settings = build(:account_saml_settings,
                       account: account,
                       enabled: true,
                       sso_url: 'https://example.com/sso',
                       certificate_fingerprint: nil)
      expect(settings.saml_enabled?).to be false
    end
  end

  describe '#sp_entity_id_or_default' do
    it 'returns sp_entity_id when present' do
      settings = build(:account_saml_settings, account: account, sp_entity_id: 'custom-entity-id')
      expect(settings.sp_entity_id_or_default).to eq('custom-entity-id')
    end

    it 'returns default entity id when sp_entity_id is blank' do
      settings = build(:account_saml_settings, account: account, sp_entity_id: '')
      expected = "chatwoot-#{account.id}"
      expect(settings.sp_entity_id_or_default).to eq(expected)
    end
  end

  describe 'scopes' do
    describe '.enabled' do
      it 'returns only enabled SAML settings' do
        enabled_setting = create(:account_saml_settings, :enabled, account: account)
        disabled_setting = create(:account_saml_settings, enabled: false)

        expect(AccountSamlSettings.enabled).to include(enabled_setting)
        expect(AccountSamlSettings.enabled).not_to include(disabled_setting)
      end
    end
  end
end
