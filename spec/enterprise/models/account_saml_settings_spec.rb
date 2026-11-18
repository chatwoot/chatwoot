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

    it 'rejects a malformed certificate after a valid one' do
      valid_certificate = build(:account_saml_settings).certificate
      malformed_certificate = "-----BEGIN CERTIFICATE-----\nbm90IGEgY2VydGlmaWNhdGU=\n-----END CERTIFICATE-----"
      settings = build(:account_saml_settings, account: account, certificate: "#{valid_certificate}#{malformed_certificate}")

      expect(settings).not_to be_valid
      expect(settings.errors[:certificate]).to include('must be a valid X.509 certificate in PEM format')
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

    it 'returns the fingerprint of the certificate that expires last when several are stored' do
      key = OpenSSL::PKey::RSA.new(2048)
      rotated = OpenSSL::X509::Certificate.new
      rotated.version = 2
      rotated.serial = 2
      rotated.subject = OpenSSL::X509::Name.parse('/CN=rotated.example.com')
      rotated.issuer = rotated.subject
      rotated.public_key = key.public_key
      rotated.not_before = Time.zone.now
      rotated.not_after = 2.years.from_now
      rotated.sign(key, OpenSSL::Digest.new('SHA256'))
      settings = build(:account_saml_settings, account: account)
      settings.signing_certificates = [valid_cert_pem.strip, rotated.to_pem.strip]

      expect(settings.certificate_fingerprint).to eq(OpenSSL::Digest::SHA1.hexdigest(rotated.to_der).upcase.scan(/../).join(':'))
    end
  end

  describe 'IdP metadata' do
    let(:metadata_url) { 'https://idp.example.com/saml/v2/metadata' }
    let(:certificate) { build(:account_saml_settings).certificate }
    let(:rotated_certificate) { build(:account_saml_settings).certificate }
    let(:metadata) { { sso_url: 'https://idp.example.com/saml/v2/SSO', idp_entity_id: metadata_url, signing_certificates: [certificate] } }
    let(:metadata_service) { instance_double(Saml::IdpMetadataService, perform: metadata) }

    before do
      allow(Saml::IdpMetadataService).to receive(:new).with(metadata_url).and_return(metadata_service)
    end

    describe 'saving with a metadata URL' do
      it 'fills the IdP fields from the metadata' do
        settings = described_class.create!(account: account, metadata_url: metadata_url)

        expect(settings).to have_attributes(metadata)
        expect(settings.metadata_refreshed_at).to be_within(1.second).of(Time.current)
      end

      it 'adds an error when the metadata cannot be read' do
        allow(metadata_service).to receive(:perform).and_raise(Saml::IdpMetadataService::Error.new(:unreachable))
        settings = described_class.new(account: account, metadata_url: metadata_url)

        expect(settings).not_to be_valid
        expect(settings.errors[:metadata_url]).to include(I18n.t('errors.account_saml_settings.metadata_url.unreachable'))
      end

      it 'adds a certificate error when the metadata has a malformed certificate' do
        malformed_certificate = "-----BEGIN CERTIFICATE-----\nbm90IGEgY2VydGlmaWNhdGU=\n-----END CERTIFICATE-----"
        allow(metadata_service).to receive(:perform).and_return(metadata.merge(signing_certificates: [certificate, malformed_certificate]))
        settings = described_class.new(account: account, metadata_url: metadata_url)

        expect(settings).not_to be_valid
        expect(settings.errors[:certificate]).to include('must be a valid X.509 certificate in PEM format')
      end

      it 'does not fetch the metadata when the URL is unchanged' do
        settings = described_class.create!(account: account, metadata_url: metadata_url)
        settings.update!(role_mappings: { 'Admins' => { 'role' => 1 } })

        expect(metadata_service).to have_received(:perform).once
      end
    end

    describe '#refresh_metadata_if_needed' do
      let(:settings) { described_class.create!(account: account, metadata_url: metadata_url) }
      let(:near_expiry) { OpenSSL::X509::Certificate.new(certificate).not_after - 10.minutes }

      before { settings }

      it 'does not fetch while a newer certificate is stored next to an expired one' do
        key = OpenSSL::PKey::RSA.new(2048)
        expired = OpenSSL::X509::Certificate.new
        expired.version = 2
        expired.serial = 1
        expired.subject = OpenSSL::X509::Name.parse('/CN=idp.example.com')
        expired.issuer = expired.subject
        expired.public_key = key.public_key
        expired.not_before = 2.years.ago
        expired.not_after = 1.year.ago
        expired.sign(key, OpenSSL::Digest.new('SHA256'))
        settings.update!(signing_certificates: [expired.to_pem.strip, certificate])

        travel_to(1.day.from_now) do
          settings.refresh_metadata_if_needed

          expect(metadata_service).to have_received(:perform).once
        end
      end

      it 'does not fetch while the certificate is far from expiry' do
        travel_to(near_expiry - 1.day) do
          settings.refresh_metadata_if_needed

          expect(metadata_service).to have_received(:perform).once
        end
      end

      it 'stores the rotated certificate when the certificate is close to expiry' do
        allow(metadata_service).to receive(:perform).and_return(metadata.merge(signing_certificates: [rotated_certificate]))

        travel_to(near_expiry) do
          settings.refresh_metadata_if_needed

          expect(settings.reload.certificate).to eq(rotated_certificate)
          expect(settings.metadata_refreshed_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'does not fetch again within the refresh interval' do
        travel_to(near_expiry) do
          settings.refresh_metadata_if_needed
          settings.refresh_metadata_if_needed

          expect(metadata_service).to have_received(:perform).twice
        end
      end

      it 'does not fetch when another request already claimed the refresh' do
        travel_to(near_expiry) do
          described_class.where(id: settings.id).update_all(metadata_refreshed_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
          settings.refresh_metadata_if_needed

          expect(metadata_service).to have_received(:perform).once
        end
      end

      it 'keeps the stored values when the fetch fails' do
        allow(metadata_service).to receive(:perform).and_raise(Saml::IdpMetadataService::Error.new(:unreachable))

        travel_to(near_expiry) do
          settings.refresh_metadata_if_needed

          expect(settings.reload.certificate).to eq(certificate)
          expect(settings.metadata_refreshed_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'keeps the stored values when the fetched metadata is invalid' do
        allow(metadata_service).to receive(:perform).and_return(metadata.merge(sso_url: nil))

        travel_to(near_expiry) do
          settings.refresh_metadata_if_needed

          expect(settings.sso_url).to eq(metadata[:sso_url])
          expect(settings.reload.sso_url).to eq(metadata[:sso_url])
        end
      end

      it 'does nothing without a metadata URL' do
        manual_settings = create(:account_saml_settings, account: create(:account))

        expect { manual_settings.refresh_metadata_if_needed }.not_to(change { manual_settings.reload.updated_at })
      end
    end

    describe '#signing_certificates' do
      it 'returns every certificate in the stored value' do
        settings = build(:account_saml_settings, account: account, certificate: "#{certificate}\n#{rotated_certificate}")

        expect(settings.signing_certificates).to eq([certificate, rotated_certificate])
      end
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
        settings.destroy
      end
    end
  end
end
