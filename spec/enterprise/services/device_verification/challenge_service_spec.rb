require 'rails_helper'

RSpec.describe DeviceVerification::ChallengeService do
  let(:user) { create(:user, password: 'Password1!') }
  let(:mailer_message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  # Plain double: the mailer class ships in a later commit; stub_const guards the constant
  let(:mailer_class) { double('Enterprise::DeviceVerificationMailer') } # rubocop:disable RSpec/VerifiedDoubles
  let(:emailed_codes) { [] }

  before do
    stub_const('Enterprise::DeviceVerificationMailer', mailer_class)
    allow(mailer_class).to receive(:verification_code) do |_user, encrypted_code, _meta|
      emailed_codes << DeviceVerification.decrypt_code(encrypted_code)
      mailer_message
    end
  end

  def issue_challenge(meta: {})
    described_class.new(user: user, request_meta: meta).issue!
  end

  describe '#issue!' do
    it 'returns a decodable device verification token and emails a 6-digit code' do
      token = issue_challenge

      claims = DeviceVerification::TokenService.new(token: token).decode_claims
      expect(claims[:user_id]).to eq(user.id)
      expect(emailed_codes.size).to eq(1)
      expect(emailed_codes.first).to match(/\A\d{6}\z/)
    end

    it 'stops issuing after the budget is exhausted' do
      10.times { expect(issue_challenge).to be_present }
      expect(issue_challenge).to be_nil
    end

    it 'self-heals an issuance counter left without expiry' do
      issue_challenge
      key = format(Redis::RedisKeys::DEVICE_VERIFICATION_ISSUANCE, user_id: user.id)
      Redis::Alfred.with { |conn| conn.persist(key) }

      issue_challenge

      expect(Redis::Alfred.ttl(key)).to be_positive
    end

    it 'releases the issuance reservation when the email cannot be enqueued' do
      allow(mailer_message).to receive(:deliver_later).and_raise(StandardError, 'queue down')
      key = format(Redis::RedisKeys::DEVICE_VERIFICATION_ISSUANCE, user_id: user.id)

      expect { issue_challenge }.to raise_error(StandardError, 'queue down')

      # Budget not consumed by the failed attempt, so a retry is still allowed.
      expect(Redis::Alfred.get(key).to_i).to eq(0)
    end
  end

  describe '.redeem' do
    let!(:token) { issue_challenge }
    let(:code) { emailed_codes.last }

    it 'redeems with the correct code exactly once' do
      expect(described_class.redeem(token: token, code: code)).to eq({ user: user })
      second = described_class.redeem(token: token, code: code)
      expect(second[:error]).to eq(:expired)
    end

    it 'rejects a wrong code and locks after 5 attempts' do
      5.times do
        expect(described_class.redeem(token: token, code: '000000')[:error]).to eq(:invalid_code)
      end
      expect(described_class.redeem(token: token, code: code)[:error]).to eq(:locked)
    end

    it 'rejects garbage tokens' do
      expect(described_class.redeem(token: 'junk', code: code)[:error]).to eq(:invalid_token)
    end

    it 'rejects redemption after a password change' do
      user.update!(password: 'NewPassword1!')
      expect(described_class.redeem(token: token, code: code)[:error]).to eq(:stale)
    end

    it 'rejects redemption if the user enabled MFA after issuance' do
      allow(User).to receive(:find_by).and_return(user)
      allow(user).to receive(:mfa_enabled?).and_return(true)
      expect(described_class.redeem(token: token, code: code)[:error]).to eq(:stale)
    end

    it 'rejects redemption for a user who can no longer authenticate' do
      allow(User).to receive(:find_by).and_return(user)
      allow(user).to receive(:active_for_authentication?).and_return(false)
      expect(described_class.redeem(token: token, code: code)[:error]).to eq(:stale)
    end

    it 'rejects redemption when the user is not a password-provider user' do
      user.update_column(:provider, 'saml') # rubocop:disable Rails/SkipsModelValidations
      expect(described_class.redeem(token: token, code: code)[:error]).to eq(:stale)
    end

    it 'reports expired when the code TTL has passed' do
      travel 11.minutes do
        result = described_class.redeem(token: token, code: code)
        expect(result[:error]).to eq(:invalid_token)
      end
    end
  end
end
