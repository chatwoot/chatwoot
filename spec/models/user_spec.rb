# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_shared.rb'
require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe User do
  let!(:user) { create(:user) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:email) }
  end

  context 'with associations' do
    it { is_expected.to have_many(:accounts).through(:account_users) }
    it { is_expected.to have_many(:account_users) }
    it { is_expected.to have_many(:assigned_conversations).class_name('Conversation').dependent(:nullify) }
    it { is_expected.to have_many(:inbox_members).dependent(:destroy_async) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy_async) }
    it { is_expected.to have_many(:messages) }
    it { is_expected.to have_many(:reporting_events) }
    it { is_expected.to have_many(:teams) }
  end

  describe 'concerns' do
    it_behaves_like 'access_tokenable'
    it_behaves_like 'avatarable'
  end

  describe 'pubsub_token' do
    before { user.update(name: Faker::Name.name) }

    it { expect(user.pubsub_token).not_to be_nil }
    it { expect(user.saved_changes.keys).not_to eq('pubsub_token') }

    context 'with rotate the pubsub_token' do
      it 'changes the pubsub_token when password changes' do
        pubsub_token = user.pubsub_token
        user.password = Faker::Internet.password(special_characters: true)
        user.save!
        expect(user.pubsub_token).not_to eq(pubsub_token)
      end

      it 'will not change pubsub_token when other attributes change' do
        pubsub_token = user.pubsub_token
        user.name = Faker::Name.name
        user.save!
        expect(user.pubsub_token).to eq(pubsub_token)
      end
    end
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

  context 'with sso_auth_token' do
    it 'can generate multiple sso tokens which can be validated' do
      sso_auth_token1 = user.generate_sso_auth_token
      sso_auth_token2 = user.generate_sso_auth_token
      expect(sso_auth_token1).present?
      expect(sso_auth_token2).present?
      expect(user.valid_sso_auth_token?(sso_auth_token1)).to be true
      expect(user.valid_sso_auth_token?(sso_auth_token2)).to be true
    end

    it 'wont validate an invalid token' do
      expect(user.valid_sso_auth_token?(SecureRandom.hex(32))).to be false
    end

    it 'wont validate an invalidated token' do
      sso_auth_token = user.generate_sso_auth_token
      user.invalidate_sso_auth_token(sso_auth_token)
      expect(user.valid_sso_auth_token?(sso_auth_token)).to be false
    end
  end

  describe 'access token' do
    it 'creates a single access token upon user creation' do
      new_user = create(:user)
      token_count = AccessToken.where(owner: new_user).count
      expect(token_count).to eq(1)
    end
  end

  context 'when user changes the email' do
    it 'mutates the value' do
      user.email = 'user@example.com'
      expect(user.will_save_change_to_email?).to be true
    end
  end

  context 'when the supplied email is uppercase' do
    it 'downcases the email on save' do
      new_user = create(:user, email: 'Test123@test.com')
      expect(new_user.email).to eq('test123@test.com')
    end
  end

  describe '#active_account_user' do
    let(:user) { create(:user) }
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let(:account3) { create(:account) }

    before do
      # Create account_users with different active_at values
      create(:account_user, user: user, account: account1, active_at: 2.days.ago)
      create(:account_user, user: user, account: account2, active_at: 1.day.ago)
      create(:account_user, user: user, account: account3, active_at: nil) # New account with NULL active_at
    end

    it 'returns the account_user with the most recent active_at, prioritizing timestamps over NULL values' do
      # Should return account2 (most recent timestamp) even though account3 was created last with NULL active_at
      expect(user.active_account_user.account_id).to eq(account2.id)
    end

    it 'returns NULL active_at account only when no other accounts have active_at' do
      # Remove active_at from all accounts
      user.account_users.each { |au| au.update!(active_at: nil) }

      # Should return one of the accounts (behavior is undefined but consistent)
      expect(user.active_account_user).to be_present
    end

    context 'when multiple accounts have NULL active_at' do
      before do
        create(:account_user, user: user, account: create(:account), active_at: nil)
      end

      it 'still prioritizes accounts with timestamps' do
        expect(user.active_account_user.account_id).to eq(account2.id)
      end
    end
  end
end
