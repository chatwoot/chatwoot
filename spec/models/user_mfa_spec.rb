require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#mfa_enabled?' do
    it 'returns column value when otp method missing' do
      user = User.new
      # simulate method not defined
      allow(user).to receive(:respond_to?).with(:otp_required_for_login?).and_return(false)
      user[:otp_required_for_login] = true

      expect { user.mfa_enabled? }.not_to raise_error
      expect(user.mfa_enabled?).to be true
    end

    it 'delegates to otp_required_for_login? when available' do
      user = User.new
      allow(user).to receive(:respond_to?).with(:otp_required_for_login?).and_return(true)
      allow(user).to receive(:otp_required_for_login?).and_return(false)

      expect(user.mfa_enabled?).to be false
    end
  end
end
