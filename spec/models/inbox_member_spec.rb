# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxMember do
  include ActiveJob::TestHelper

  describe '#DestroyAssociationAsyncJob' do
    let(:inbox_member) { create(:inbox_member) }

    # ref: https://github.com/chatwoot/chatwoot/issues/4616
    context 'when parent inbox is destroyed' do
      it 'enques and processes DestroyAssociationAsyncJob' do
        perform_enqueued_jobs do
          inbox_member.inbox.destroy!
        end
        expect { inbox_member.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'filtered unread count invalidation' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user) }
    let(:store) { Conversations::UnreadCounts::FilteredCountStore }

    before do
      account.enable_features!(:unread_count_for_filters)
    end

    it 'invalidates the user built-in filter version when inbox access is added' do
      expect do
        create(:inbox_member, inbox: inbox, user: user)
      end.to change { store.built_in_filter_version(account_id: account.id, user_id: user.id) }.by(1)
    end

    it 'invalidates the user built-in filter version when inbox access is removed' do
      inbox_member = create(:inbox_member, inbox: inbox, user: user)

      expect do
        inbox_member.destroy!
      end.to change { store.built_in_filter_version(account_id: account.id, user_id: user.id) }.by(1)
    end

    it 'invalidates the user built-in filter version when the parent inbox is removed' do
      create(:inbox_member, inbox: inbox, user: user)

      expect do
        perform_enqueued_jobs { inbox.destroy! }
      end.to change { store.built_in_filter_version(account_id: account.id, user_id: user.id) }.by(1)
    end

    it 'invalidates administrator built-in filter versions when the parent inbox is removed' do
      admin = create(:user)
      create(:account_user, account: account, user: admin, role: :administrator)

      expect do
        perform_enqueued_jobs { inbox.destroy! }
      end.to change { store.built_in_filter_version(account_id: account.id, user_id: admin.id) }.by(1)
    end
  end
end
