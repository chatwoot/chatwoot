require 'rails_helper'

RSpec.describe DeviceVerification::TokenService do
  let(:user) { create(:user, password: 'Password1!') }

  describe '#generate_token / #decode_claims' do
    it 'round-trips the device verification claims' do
      token = described_class.new(user: user, jti: 'abc123').generate_token
      claims = described_class.new(token: token).decode_claims

      expect(claims[:user_id]).to eq(user.id)
      expect(claims[:jti]).to eq('abc123')
      expect(claims[:type]).to eq('device_verification')
      expect(claims[:stamp]).to eq(described_class.stamp_for(user))
    end

    it 'rejects an MFA token (no type claim)' do
      mfa_token = Mfa::TokenService.new(user: user).generate_token
      expect(described_class.new(token: mfa_token).decode_claims).to eq({})
    end

    it 'rejects garbage tokens' do
      expect(described_class.new(token: 'not-a-jwt').decode_claims).to eq({})
    end

    it 'expires after 10 minutes' do
      token = described_class.new(user: user, jti: 'abc123').generate_token
      travel 11.minutes do
        expect(described_class.new(token: token).decode_claims).to eq({})
      end
    end

    it 'changes the stamp when the password changes' do
      original_stamp = described_class.stamp_for(user)
      user.update!(password: 'NewPassword1!')
      expect(described_class.stamp_for(user.reload)).not_to eq(original_stamp)
    end

    it 'changes the stamp when the email actually changes (post-confirmation)' do
      original_stamp = described_class.stamp_for(user)
      user.skip_reconfirmation!
      user.update!(email: 'changed@example.com')
      expect(described_class.stamp_for(user.reload)).not_to eq(original_stamp)
    end
  end

  describe 'Mfa::TokenService purpose check' do
    it 'rejects tokens carrying a type claim' do
      device_token = described_class.new(user: user, jti: 'abc123').generate_token
      expect(Mfa::TokenService.new(token: device_token).verify_token).to be_nil
    end

    it 'still accepts its own tokens' do
      mfa_token = Mfa::TokenService.new(user: user).generate_token
      expect(Mfa::TokenService.new(token: mfa_token).verify_token).to eq(user)
    end
  end
end
