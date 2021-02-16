# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_spec.rb'

RSpec.describe User do
  let!(:user) { create(:user) }

  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(1) }
  end

  context 'associations' do
    it { is_expected.to have_many(:accounts).through(:account_users) }
    it { is_expected.to have_many(:account_users) }
    it { is_expected.to have_many(:assigned_conversations).class_name('Conversation').dependent(:nullify) }
    it { is_expected.to have_many(:inbox_members).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:messages) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:teams) }
  end

  describe 'concerns' do
    it_behaves_like 'access_tokenable'
  end

  describe 'pubsub_token' do
    before { user.update(name: Faker::Name.name) }

    it { expect(user.pubsub_token).not_to eq(nil) }
    it { expect(user.saved_changes.keys).not_to eq('pubsub_token') }
  end

  describe 'hmac_identifier' do
    it 'return nil if CHATWOOT_INBOX_HMAC_KEY is not set' do
      expect(user.hmac_identifier).to eq('')
    end

    it 'return value if CHATWOOT_INBOX_HMAC_KEY is set' do
      ConfigLoader.new.process
      i = InstallationConfig.find_by(name: 'CHATWOOT_INBOX_HMAC_KEY')
      i.value = 'random_secret_key'
      i.save!
      GlobalConfig.clear_cache

      expected_hmac_identifier = OpenSSL::HMAC.hexdigest('sha256', 'random_secret_key', user.email)

      expect(user.hmac_identifier).to eq expected_hmac_identifier
    end
  end

  context 'sso_auth_token' do
    it 'can generate multiple sso tokens which can be validated' do
      sso_auth_token1 = user.generate_sso_auth_token
      sso_auth_token2 = user.generate_sso_auth_token
      expect(sso_auth_token1).present?
      expect(sso_auth_token2).present?
      expect(user.valid_sso_auth_token?(sso_auth_token1)).to eq true
      expect(user.valid_sso_auth_token?(sso_auth_token2)).to eq true
    end

    it 'wont validate an invalid token' do
      expect(user.valid_sso_auth_token?(SecureRandom.hex(32))).to eq false
    end

    it 'wont validate an invalidated token' do
      sso_auth_token = user.generate_sso_auth_token
      user.invalidate_sso_auth_token(sso_auth_token)
      expect(user.valid_sso_auth_token?(sso_auth_token)).to eq false
    end
  end
end
