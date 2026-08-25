require 'rails_helper'

RSpec.describe TelnyxSmsConfig do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:api_key) }
    it { is_expected.to validate_presence_of(:messaging_profile_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:channel_telnyx_sms).class_name('Channel::TelnyxSms') }
  end
end
