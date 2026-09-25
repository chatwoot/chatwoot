require 'rails_helper'

describe Mfa::SetupTokenService do
  before do
    skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
  end

  let(:user) { create(:user, password: 'Test@123456') }

  describe '#generate_token' do
    it 'includes user_id and token_type in the payload' do
      token = described_class.new(user: user).generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
      expect(decoded['user_id']).to eq(user.id)
      expect(decoded['token_type']).to eq('mfa_setup')
    end
  end

  describe '#verify_token' do
    it 'round trips a valid token' do
      token = described_class.new(user: user).generate_token
      expect(described_class.new(token: token).verify_token).to eq(user)
    end

    it 'rejects an expired token' do
      token = described_class.new(user: user).generate_token
      travel_to(11.minutes.from_now) do
        expect(described_class.new(token: token).verify_token).to be_nil
      end
    end

    it 'rejects a login mfa token' do
      login_token = Mfa::TokenService.new(user: user).generate_token
      expect(described_class.new(token: login_token).verify_token).to be_nil
    end

    it 'rejects the token after a password change' do
      token = described_class.new(user: user).generate_token
      user.update!(password: 'NewPassword1!', password_confirmation: 'NewPassword1!')
      expect(described_class.new(token: token).verify_token).to be_nil
    end

    it 'rejects a garbage token' do
      expect(described_class.new(token: 'garbage').verify_token).to be_nil
    end

    it 'rejects a token for a deleted user' do
      token = described_class.new(user: user).generate_token
      user.destroy!
      expect(described_class.new(token: token).verify_token).to be_nil
    end
  end
end
