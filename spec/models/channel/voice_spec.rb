require 'rails_helper'

RSpec.describe Channel::Voice do
  let(:account) { create(:account) }

  it 'reports Voice as its channel name' do
    expect(create(:channel_voice, account: account).name).to eq('Voice')
  end

  describe 'phone_number' do
    it 'accepts an E.164 number' do
      expect(build(:channel_voice, account: account, phone_number: '+886222222222')).to be_valid
    end

    it 'rejects a number without the country prefix' do
      channel = build(:channel_voice, account: account, phone_number: '0222222222')

      expect(channel).not_to be_valid
      expect(channel.errors[:phone_number]).to be_present
    end

    it 'rejects a blank number' do
      expect(build(:channel_voice, account: account, phone_number: nil)).not_to be_valid
    end

    it 'rejects a number already used by another inbox on the same account' do
      create(:channel_voice, account: account, phone_number: '+886222222222')

      expect(build(:channel_voice, account: account, phone_number: '+886222222222')).not_to be_valid
    end

    it 'allows the same number on a different account' do
      create(:channel_voice, account: account, phone_number: '+886222222222')

      expect(build(:channel_voice, account: create(:account), phone_number: '+886222222222')).to be_valid
    end

    it 'does not let an existing number be rewritten in place' do
      channel = create(:channel_voice, account: account, phone_number: '+886222222222')

      channel.update!(phone_number: '+886333333333')

      expect(channel.reload.phone_number).to eq('+886222222222')
    end
  end
end
