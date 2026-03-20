# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountSamlSettings, type: :model do
  let(:account) { create(:account) }
  let(:saml_settings) { build(:account_saml_settings, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    it 'requires sso_url' do
      settings = build(:account_saml_settings, account: account, sso_url: nil)
      expect(settings).not_to be_valid
      expect(settings.errors[:sso_url]).to include("can't be blank")
    end

    it 'requires certificate' do
      settings = build(:account_saml_settings, account: account, certificate: nil)
      expect(settings).not_to be_valid
      expect(settings.errors[:certificate]).to include("can't be blank")
    end

    it 'requires idp_entity_id' do
      settings = build(:account_saml_settings, account: account, idp_entity_id: nil)
      expect(settings).not_to be_valid
      expect(settings.errors[:idp_entity_id]).to include("can't be blank")
    end
  end

  describe '#saml_enabled?' do
    it 'returns true when required fields are present' do
      settings = build(:account_saml_settings,
                       account: account,
                       sso_url: 'https://example.com/sso',
                       certificate: 'valid-certificate')
      expect(settings.saml_enabled?).to be true
    end

    it 'returns false when sso_url is missing' do
      settings = build(:account_saml_settings,
                       account: account,
                       sso_url: nil,
                       certificate: 'valid-certificate')
      expect(settings.saml_enabled?).to be false
    end

    it 'returns false when certificate is missing' do
      settings = build(:account_saml_settings,
                       account: account,
                       sso_url: 'https://example.com/sso',
                       certificate: nil)
      expect(settings.saml_enabled?).to be false
    end
  end

  describe 'sp_entity_id auto-generation' do
    it 'automatically generates sp_entity_id when creating' do
      settings = build(:account_saml_settings, account: account, sp_entity_id: nil)
      expect(settings).to be_valid
      settings.save!
      expect(settings.sp_entity_id).to eq("http://localhost:3000/saml/sp/#{account.id}")
    end

    it 'does not override existing sp_entity_id' do
      custom_id = 'https://custom.example.com/saml/sp/123'
      settings = build(:account_saml_settings, account: account, sp_entity_id: custom_id)
      settings.save!
      expect(settings.sp_entity_id).to eq(custom_id)
    end
  end

  describe '#certificate_fingerprint' do
    let(:valid_cert_pem) do
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse('/C=US/ST=Test/L=Test/O=Test/CN=test.example.com')
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.zone.now
      cert.not_after = cert.not_before + (365 * 24 * 60 * 60)
      cert.sign(key, OpenSSL::Digest.new('SHA256'))
      cert.to_pem
    end

    it 'returns fingerprint for valid certificate' do
      settings = build(:account_saml_settings, account: account, certificate: valid_cert_pem)
      fingerprint = settings.certificate_fingerprint

      expect(fingerprint).to be_present
      expect(fingerprint).to match(/^[A-F0-9]{2}(:[A-F0-9]{2}){19}$/) # SHA1 fingerprint format
    end

    it 'returns nil for blank certificate' do
      settings = build(:account_saml_settings, account: account, certificate: '')
      expect(settings.certificate_fingerprint).to be_nil
    end

    it 'returns nil for invalid certificate' do
      settings = build(:account_saml_settings, account: account, certificate: 'invalid-cert-data')
      expect(settings.certificate_fingerprint).to be_nil
    end

    it 'formats fingerprint correctly' do
      settings = build(:account_saml_settings, account: account, certificate: valid_cert_pem)
      fingerprint = settings.certificate_fingerprint

      # Should be uppercase with colons separating each byte
      expect(fingerprint).to match(/^[A-F0-9:]+$/)
      expect(fingerprint.count(':')).to eq(19) # 20 bytes = 19 colons
    end
  end

  describe 'callbacks' do
    describe 'after_create_commit' do
      it 'queues job to set account users to saml provider' do
        expect(Saml::UpdateAccountUsersProviderJob).to receive(:perform_later).with(account.id, 'saml')
        create(:account_saml_settings, account: account)
      end
    end

    describe 'after_destroy_commit' do
      it 'queues job to reset account users provider' do
        settings = create(:account_saml_settings, account: account)
        expect(Saml::UpdateAccountUsersProviderJob).to receive(:perform_later).with(account.id, 'email')
        settings.destroy!
      end
    end
  end
end
