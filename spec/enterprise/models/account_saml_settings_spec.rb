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

    it 'requires sp_entity_id' do
      settings = build(:account_saml_settings, account: account, sp_entity_id: nil)
      expect(settings).not_to be_valid
      expect(settings.errors[:sp_entity_id]).to include("can't be blank")
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

  describe 'callbacks' do
    describe 'after_create_commit' do
      it 'queues job to set account users to saml provider' do
        expect(UpdateAccountUsersProviderJob).to receive(:perform_later).with(account.id, 'saml')
        create(:account_saml_settings, account: account)
      end
    end

    describe 'after_destroy_commit' do
      it 'queues job to reset account users provider' do
        settings = create(:account_saml_settings, account: account)
        expect(UpdateAccountUsersProviderJob).to receive(:perform_later).with(account.id, 'email')
        settings.destroy
      end
    end
  end
end
