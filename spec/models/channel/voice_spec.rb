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

  describe 'pathors_phone_number_id' do
    let(:unbind_url) { 'https://api.pathors.com/project/proj_123/integration/chatwoot/phone_numbers/pn_x9k2/binding' }

    before { create(:integrations_hook, :pathors, account: account, access_token: 'pathors_access_token') }

    it 'releases the Pathors binding when the channel is destroyed' do
      channel = create(:channel_voice, account: account, phone_number: '+886222222222', pathors_phone_number_id: 'pn_x9k2')
      stub_request(:delete, unbind_url).to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      channel.destroy!

      expect(WebMock).to have_requested(:delete, unbind_url)
    end

    it 'does not call Pathors for a channel that never bound a number' do
      create(:channel_voice, account: account, phone_number: '+886222222222').destroy!

      expect(WebMock).not_to have_requested(:delete, unbind_url)
    end
  end
end
