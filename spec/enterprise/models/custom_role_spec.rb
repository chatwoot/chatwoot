require 'rails_helper'

RSpec.describe CustomRole, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:account_users).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'unread filter count invalidation' do
    it 'notifies assigned users when permissions change' do
      account = create(:account)
      custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
      account_user = create(:account_user, account: account, custom_role: custom_role)
      notifier = instance_double(Conversations::UnreadCounts::UserFilterNotifier, perform: true)
      allow(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).and_return(notifier)

      custom_role.update!(permissions: ['conversation_manage'])

      expect(Conversations::UnreadCounts::UserFilterNotifier).to have_received(:new).with(
        account: account,
        user: account_user.user
      )
      expect(notifier).to have_received(:perform)
    end

    it 'notifies assigned users when the custom role is destroyed' do
      account = create(:account)
      custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
      account_user = create(:account_user, account: account, custom_role: custom_role)
      notifier = instance_double(Conversations::UnreadCounts::UserFilterNotifier, perform: true)
      allow(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).and_return(notifier)

      custom_role.destroy!

      expect(Conversations::UnreadCounts::UserFilterNotifier).to have_received(:new).with(
        account: account,
        user: account_user.user
      )
      expect(notifier).to have_received(:perform)
    end
  end
end
