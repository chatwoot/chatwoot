require 'rails_helper'

RSpec.describe FeatureAccess do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:access) { described_class.new(account) }
  let(:agent_membership) { account.account_users.find_by(user: agent) }
  let(:administrator_membership) { account.account_users.find_by(user: administrator) }

  describe '#allows?' do
    it 'denies a missing membership and a membership of another account' do
      other_account_member = create(:user, account: create(:account), role: :administrator).account_users.first

      expect(access.allows?(nil, 'internal_chat.access')).to be(false)
      expect(access.allows?(other_account_member, 'internal_chat.access')).to be(false)
    end

    it 'gives agents the capability default and administrators everything' do
      stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })

      expect(access.allows?(agent_membership, 'internal_chat.access')).to be(false)
      expect(access.allows?(administrator_membership, 'internal_chat.access')).to be(true)
    end

    it 'fails loudly on a capability nobody registered' do
      expect { access.allows?(agent_membership, 'internal_chat.acess') }.to raise_error(KeyError)
    end
  end

  describe '#users_with' do
    it 'lists only members of the account holding the capability' do
      outsider = create(:user, account: create(:account), role: :administrator)
      agent
      stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })

      expect(access.users_with('internal_chat.access')).to contain_exactly(administrator)
      expect(access.users_with('internal_chat.access')).not_to include(outsider)
    end

    it 'lists every member when agents hold the capability by default' do
      expect(access.users_with('internal_chat.access')).to contain_exactly(administrator, agent)
    end
  end
end
