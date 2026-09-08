require 'rails_helper'

RSpec.describe CustomRole, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:account_users).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'filtered unread count invalidation' do
    let(:account) { create(:account) }
    let(:custom_role) { create(:custom_role, account: account, permissions: ['conversation_manage']) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:invalidator) { instance_double(Conversations::UnreadCounts::FilteredCountInvalidator, users_visibility_changed!: true) }

    before do
      create(:account_user, account: account, user: user, custom_role: custom_role)
      create(:account_user, account: account, user: other_user, custom_role: custom_role)
      allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'invalidates filtered counts for assigned users when permissions change' do
      custom_role.update!(permissions: ['conversation_participating_manage'])

      expect(invalidator).to have_received(:users_visibility_changed!).with(user_ids: contain_exactly(user.id, other_user.id))
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        'account.cache_invalidated',
        kind_of(Time),
        account: account,
        cache_keys: account.cache_keys
      )
    end

    it 'does not invalidate filtered counts when permissions are unchanged' do
      custom_role.update!(name: 'Support manager')

      expect(invalidator).not_to have_received(:users_visibility_changed!)
    end

    it 'invalidates filtered counts for assigned users when the role is deleted' do
      custom_role.destroy!

      expect(invalidator).to have_received(:users_visibility_changed!).with(user_ids: contain_exactly(user.id, other_user.id))
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        'account.cache_invalidated',
        kind_of(Time),
        account: account,
        cache_keys: account.cache_keys
      )
    end
  end
end
