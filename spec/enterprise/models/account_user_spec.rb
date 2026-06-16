# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountUser, type: :model do
  describe 'associations' do
    # option and dependant nullify
    it { is_expected.to belong_to(:custom_role).optional }
  end

  describe 'permissions' do
    context 'when custom role is assigned' do
      it 'returns permissions of the custom role along with `custom_role` permission' do
        account = create(:account)
        custom_role = create(:custom_role, account: account)
        account_user = create(:account_user, account: account, custom_role: custom_role)

        expect(account_user.permissions).to eq(custom_role.permissions + ['custom_role'])
      end
    end

    context 'when custom role is not assigned' do
      it 'returns permissions of the default role' do
        account = create(:account)
        account_user = create(:account_user, account: account)

        expect(account_user.permissions).to eq([account_user.role])
      end
    end
  end

  describe 'unread filter count invalidation' do
    it 'notifies when the assigned custom role changes' do
      account = create(:account)
      custom_role = create(:custom_role, account: account)
      account_user = create(:account_user, account: account)
      notifier = instance_double(Conversations::UnreadCounts::UserFilterNotifier, perform: true)
      allow(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).and_return(notifier)

      account_user.update!(custom_role: custom_role)

      expect(Conversations::UnreadCounts::UserFilterNotifier).to have_received(:new).with(
        account: account,
        user: account_user.user
      )
      expect(notifier).to have_received(:perform)
    end
  end

  describe 'audit log' do
    context 'when account user is created' do
      it 'has associated audit log created' do
        account_user = create(:account_user)
        account_user_audit_log = Audited::Audit.where(auditable_type: 'AccountUser', action: 'create').first
        expect(account_user_audit_log).to be_present
        expect(account_user_audit_log.associated).to eq(account_user.account)
      end
    end

    context 'when account user is updated' do
      it 'has associated audit log created' do
        account_user = create(:account_user)
        account_user.update!(availability: 'offline')
        account_user_audit_log = Audited::Audit.where(auditable_type: 'AccountUser', action: 'update').first
        expect(account_user_audit_log).to be_present
        expect(account_user_audit_log.associated).to eq(account_user.account)
        expect(account_user_audit_log.audited_changes).to eq('availability' => [0, 1])
      end
    end
  end
end
