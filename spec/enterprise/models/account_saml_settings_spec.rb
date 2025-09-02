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
end
