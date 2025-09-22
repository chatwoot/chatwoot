require 'rails_helper'

describe Mfa::AuthenticationService do
  before do
    skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
    user.enable_two_factor!
    user.update!(otp_required_for_login: true)
  end

  let(:user) { create(:user) }

  describe '#authenticate' do
    context 'with OTP code' do
      context 'when OTP is valid' do
        it 'returns true' do
          valid_otp = user.current_otp
          service = described_class.new(user: user, otp_code: valid_otp)
          expect(service.authenticate).to be_truthy
        end
      end

      context 'when OTP is invalid' do
        it 'returns false' do
          service = described_class.new(user: user, otp_code: '000000')
          expect(service.authenticate).to be_falsey
        end
      end

      context 'when OTP is nil' do
        it 'returns false' do
          service = described_class.new(user: user, otp_code: nil)
          expect(service.authenticate).to be_falsey
        end
      end
    end

    context 'with backup code' do
      let(:backup_codes) { user.generate_backup_codes! }

      context 'when backup code is valid' do
        it 'returns true and invalidates the code' do
          valid_code = backup_codes.first
          service = described_class.new(user: user, backup_code: valid_code)

          expect(service.authenticate).to be_truthy

          # Code should be invalidated after use
          user.reload
          expect(user.otp_backup_codes).to include('XXXXXXXX')
        end
      end

      context 'when backup code is invalid' do
        it 'returns false' do
          service = described_class.new(user: user, backup_code: 'invalid')
          expect(service.authenticate).to be_falsey
        end
      end

      context 'when backup code has already been used' do
        it 'returns false' do
          valid_code = backup_codes.first
          # Use the code once
          service = described_class.new(user: user, backup_code: valid_code)
          service.authenticate

          # Try to use it again
          service2 = described_class.new(user: user.reload, backup_code: valid_code)
          expect(service2.authenticate).to be_falsey
        end
      end
    end

    context 'with neither OTP nor backup code' do
      it 'returns false' do
        service = described_class.new(user: user)
        expect(service.authenticate).to be_falsey
      end
    end

    context 'when user is nil' do
      it 'returns false' do
        service = described_class.new(user: nil, otp_code: '123456')
        expect(service.authenticate).to be_falsey
      end
    end

    context 'when both OTP and backup code are provided' do
      it 'uses OTP authentication first' do
        valid_otp = user.current_otp
        backup_codes = user.generate_backup_codes!

        service = described_class.new(
          user: user,
          otp_code: valid_otp,
          backup_code: backup_codes.first
        )

        expect(service.authenticate).to be_truthy
        # Backup code should not be consumed
        user.reload
        expect(user.otp_backup_codes).not_to include('XXXXXXXX')
      end
    end
  end
end
