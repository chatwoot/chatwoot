require 'rails_helper'

describe Whatsapp::IdentifierSyncService do
  let!(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let!(:inbox) { channel.inbox }
  let(:account) { inbox.account }
  let(:contact) { create(:contact, account: account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5511999999999') }

  def sync(source_ids)
    described_class.new(contact_inbox: contact_inbox, contact: contact).perform(source_ids: source_ids)
  end

  def group_of(source_id)
    inbox.contact_inboxes.find_by(source_id: source_id).identity_group_id
  end

  describe 'identity group' do
    it 'puts identifiers that arrive in the same payload in one group' do
      sync(['5511999999999', 'BR.1234567890'])

      expect(group_of('5511999999999')).to be_present
      expect(group_of('BR.1234567890')).to eq(group_of('5511999999999'))
    end

    it 'keeps the group of a row that already has one' do
      sync(['5511999999999'])
      original = group_of('5511999999999')

      sync(['5511999999999', 'BR.1234567890'])

      expect(group_of('5511999999999')).to eq(original)
      expect(group_of('BR.1234567890')).to eq(original)
    end

    it 'gives a row that arrives alone a group of its own' do
      other = create(:contact_inbox, contact: create(:contact, account: account), inbox: inbox, source_id: 'BR.9999999999')
      sync(['5511999999999'])

      expect(group_of('5511999999999')).to be_present
      expect(other.reload.identity_group_id).to be_nil
    end

    it 'does not join two identifiers that already belong to different groups' do
      create(:contact_inbox, contact: contact, inbox: inbox, source_id: 'BR.1234567890')
      sync(['5511999999999'])
      sync(['BR.1234567890'])
      phone_group = group_of('5511999999999')
      bsuid_group = group_of('BR.1234567890')

      sync(['5511999999999', 'BR.1234567890'])

      expect(group_of('5511999999999')).to eq(phone_group)
      expect(group_of('BR.1234567890')).to eq(bsuid_group)
      expect(phone_group).not_to eq(bsuid_group)
    end

    it 'does not group rows from another inbox that share a source id' do
      other_channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                                validate_provider_config: false, sync_templates: false)
      elsewhere = create(:contact_inbox, contact: contact, inbox: other_channel.inbox, source_id: 'BR.1234567890')

      sync(['5511999999999', 'BR.1234567890'])

      expect(elsewhere.reload.identity_group_id).to be_nil
    end

    it 'leaves groups alone when a merge brings rows together' do
      mergee = create(:contact, account: account)
      merged_inbox = create(:contact_inbox, contact: mergee, inbox: inbox, source_id: 'BR.5555555555')
      sync(['5511999999999'])
      described_class.new(contact_inbox: merged_inbox, contact: mergee).perform(source_ids: ['BR.5555555555'])
      phone_group = group_of('5511999999999')
      merged_group = group_of('BR.5555555555')

      ContactMergeAction.new(account: account, base_contact: contact, mergee_contact: mergee).perform

      expect(group_of('5511999999999')).to eq(phone_group)
      expect(group_of('BR.5555555555')).to eq(merged_group)
      expect(phone_group).not_to eq(merged_group)
    end
  end
end
