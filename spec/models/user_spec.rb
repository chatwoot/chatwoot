# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_spec.rb'

RSpec.describe User do
  let!(:user) { create(:user) }

  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
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
