require 'rails_helper'

# A group contact is account-scoped, so one WhatsApp group can belong to two inboxes of
# the same account. `group_left` used to be a boolean on that shared contact, and one
# number leaving marked the group as left for every other number in it.
# Not a class: what it describes is one column and the three methods around it, which
# read very differently from the rest of ContactInbox.
RSpec.describe 'the inbox a WhatsApp group was left from' do # rubocop:disable RSpec/DescribeClass
  let(:account) { create(:account) }
  let(:group) { create(:contact, account: account, group_type: :group, identifier: '120363041234567890@g.us') }
  let!(:first) { create(:contact_inbox, contact: group, inbox: create(:inbox, account: account), source_id: '120363041234567890') }
  let!(:second) { create(:contact_inbox, contact: group, inbox: create(:inbox, account: account), source_id: '120363041234567891') }

  it 'leaves the inboxes that stayed in the group' do
    first.mark_group_left!

    expect(first.group_left?).to be(true)
    expect(second.reload.group_left?).to be(false)
  end

  it 'clears it for the inbox that rejoined, and leaves the other one alone' do
    first.mark_group_left!
    second.mark_group_left!

    first.mark_group_rejoined!

    expect(first.group_left?).to be(false)
    expect(second.reload.group_left?).to be(true)
  end

  it 'does not restamp an inbox that already left' do
    first.mark_group_left!

    expect { first.mark_group_left! }.not_to(change { first.reload.group_left_at })
  end

  # The migration that added the column deleted `group_left` from every contact, so a
  # truthy one can only come from a worker of the release before it: the rolling deploy
  # window, where a group left through the old code would otherwise read as still joined.
  context 'with a contact a previous release wrote to' do
    before { group.update!(additional_attributes: { 'group_left' => true }) }

    it 'reads the old boolean while the column says nothing' do
      expect(first.group_left?).to be(true)
      expect(second.group_left?).to be(true)
    end

    it 'stops reading it once the inbox rejoins' do
      first.mark_group_left!
      first.mark_group_rejoined!

      expect(first.group_left?).to be(false)
      expect(second.reload.group_left?).to be(true)
    end
  end

  describe 'Contact#group_left_in?' do
    it 'answers for the inbox it is asked about' do
      first.mark_group_left!

      expect(group.group_left_in?(first.inbox_id)).to be(true)
      expect(group.group_left_in?(second.inbox_id)).to be(false)
      expect(group.group_left_in?(nil)).to be(false)
    end
  end
end
