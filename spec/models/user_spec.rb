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

  describe '2FA/MFA functionality' do
    let(:user) { create(:user, password: 'Test@123456') }

    describe '#enable_two_factor!' do
      it 'generates OTP secret for 2FA setup' do
        expect(user.otp_secret).to be_nil
        expect(user.otp_required_for_login).to be_falsey

        user.enable_two_factor!

        expect(user.otp_secret).not_to be_nil
        # otp_required_for_login is false until verification is complete
        expect(user.otp_required_for_login).to be_falsey
      end
    end

    describe '#disable_two_factor!' do
      before do
        user.enable_two_factor!
        user.update!(otp_required_for_login: true) # Simulate verified 2FA
        user.generate_otp_backup_codes!
      end

      it 'disables 2FA and clears OTP secret' do
        user.disable_two_factor!

        expect(user.otp_secret).to be_nil
        expect(user.otp_required_for_login).to be_falsey
        expect(user.otp_backup_codes).to be_blank # Can be nil or empty array
      end
    end

    describe '#generate_otp_backup_codes!' do
      before do
        user.enable_two_factor!
      end

      it 'generates 10 backup codes' do
        codes = user.generate_otp_backup_codes!

        expect(codes).to be_an(Array)
        expect(codes.length).to eq(10)
        expect(codes.first).to match(/\A\d{6}\z/) # 6-digit codes
        expect(user.otp_backup_codes).not_to be_nil
      end
    end

    describe '#invalidate_otp_backup_code!' do
      let(:backup_codes) { user.generate_otp_backup_codes! }

      before do
        user.enable_two_factor!
        backup_codes # Generate codes
      end

      it 'invalidates a used backup code' do
        code = backup_codes.first

        user.invalidate_otp_backup_code!(code)
        user.reload

        # The code should be marked as used (replaced with X's)
        decrypted_codes = user.otp_backup_codes
        expect(decrypted_codes).to include('XXXXXX')
      end

      it 'returns false for invalid backup code' do
        result = user.invalidate_otp_backup_code!('invalid')
        expect(result).to be_falsey
      end
    end

    describe '#two_factor_provisioning_uri' do
      before do
        user.enable_two_factor!
      end

      it 'generates a valid provisioning URI for QR code' do
        uri = user.two_factor_provisioning_uri

        expect(uri).to include('otpauth://totp/')
        expect(uri).to include(CGI.escape(user.email))
        expect(uri).to include('Chatwoot')
      end
    end

    describe '#two_factor_qr_code_svg' do
      before do
        user.enable_two_factor!
      end

      it 'generates QR code SVG' do
        svg = user.two_factor_qr_code_svg

        expect(svg).to include('<svg')
        expect(svg).to include('</svg>')
      end
    end

    describe '#validate_otp_backup_code' do
      let(:backup_codes) { user.generate_otp_backup_codes! }

      before do
        user.enable_two_factor!
        backup_codes
      end

      it 'validates correct backup code' do
        code = backup_codes.first
        result = user.validate_otp_backup_code(code)
        expect(result).to be_truthy
      end

      it 'rejects invalid backup code' do
        result = user.validate_otp_backup_code('invalid')
        expect(result).to be_falsey
      end

      it 'rejects already used backup code' do
        code = backup_codes.first
        user.invalidate_otp_backup_code!(code)

        result = user.validate_otp_backup_code(code)
        expect(result).to be_falsey
      end
    end
  end
end
