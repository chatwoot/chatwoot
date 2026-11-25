require 'rails_helper'

RSpec.describe Whatsapp::Session::Owner do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'uazapi', phone_number: '+5541999990000',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: '1203630001@g.us') }

  before { channel.update!(provider_connection: { 'connection' => 'open', 'lid' => '900000100000000' }) }

  describe '.group_member' do
    # The case the phone can never answer: WhatsApp discloses no number for the connected
    # account, so the roster names it by LID and the contact carries no phone at all.
    it 'finds the connected account when the roster only knows its LID' do
      contact = create(:contact, account: account, phone_number: nil, identifier: '900000100000000@lid')
      member = create(:group_member, group_contact: group_contact, contact: contact, role: 'admin')

      expect(described_class.group_member(channel, group_contact)).to eq(member)
      expect(described_class.admin?(channel, group_contact)).to be(true)
    end

    # Brazilian lines are reported with or without the ninth digit depending on when they
    # were registered, so the number the operator typed and the one on the roster differ.
    it 'finds it under the other ninth-digit form of the configured number' do
      contact = create(:contact, account: account, phone_number: '+554199990000')
      member = create(:group_member, group_contact: group_contact, contact: contact, role: 'member')

      expect(described_class.group_member(channel, group_contact)).to eq(member)
      expect(described_class.admin?(channel, group_contact)).to be(false)
    end

    it 'is nobody when the roster holds neither identity' do
      create(:group_member, group_contact: group_contact, contact: create(:contact, account: account, phone_number: '+5511888880000'))

      expect(described_class.group_member(channel, group_contact)).to be_nil
    end

    it 'is nobody without a channel to be' do
      expect(described_class.group_member(nil, group_contact)).to be_nil
    end
  end
end
