require 'rails_helper'

RSpec.describe ChannelGroup do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'requires a name' do
      expect(build(:channel_group, account: account, name: ' ')).not_to be_valid
    end

    it 'rejects a name already used in the account, ignoring case' do
      create(:channel_group, account: account, name: 'Northstar')

      expect(build(:channel_group, account: account, name: 'northstar')).not_to be_valid
    end

    it 'allows the same name in another account' do
      create(:channel_group, account: account, name: 'Northstar')

      expect(build(:channel_group, account: create(:account), name: 'Northstar')).to be_valid
    end
  end

  describe 'members' do
    it 'keeps its inboxes when the group is deleted' do
      channel_group = create(:channel_group, account: account)
      inbox = create(:inbox, account: account, channel_group: channel_group)

      channel_group.destroy!

      expect(inbox.reload).to be_persisted
      expect(inbox.channel_group_id).to be_nil
    end
  end
end
