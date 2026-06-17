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

  describe 'unread filter count invalidation' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user) { create(:user, account: account, role: :agent) }
    let(:notifier) { instance_double(Conversations::UnreadCounts::UserFilterNotifier, perform: true) }

    before do
      allow(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).and_return(notifier)
    end

    it 'notifies when inbox access is added' do
      create(:inbox_member, inbox: inbox, user: user)

      expect(Conversations::UnreadCounts::UserFilterNotifier).to have_received(:new).with(account: account, user: user)
      expect(notifier).to have_received(:perform)
    end

    it 'notifies when inbox access is removed' do
      inbox_member = create(:inbox_member, inbox: inbox, user: user)
      expect(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).with(account: account, user: user).and_return(notifier)
      expect(notifier).to receive(:perform)

      inbox_member.destroy!
    end
  end
end
