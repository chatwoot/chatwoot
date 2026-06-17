# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountUser do
  include ActiveJob::TestHelper

  let!(:account_user) { create(:account_user) }
  let!(:inbox) { create(:inbox, account: account_user.account) }

  describe 'notification_settings' do
    it 'gets created with the right default settings' do
      expect(account_user.user.notification_settings).not_to be_nil

      expect(account_user.user.notification_settings.first.email_conversation_creation?).to be(false)
      expect(account_user.user.notification_settings.first.email_conversation_assignment?).to be(true)
    end
  end

  describe 'permissions' do
    it 'returns the right permissions' do
      expect(account_user.permissions).to eq(['agent'])
    end

    it 'returns the right permissions for administrator' do
      account_user.administrator!
      expect(account_user.permissions).to eq(['administrator'])
    end
  end

  describe 'destroy call agent::destroy service' do
    it 'gets created with the right default settings' do
      create(:conversation, account: account_user.account, assignee: account_user.user, inbox: inbox)
      user = account_user.user

      expect(user.assigned_conversations.count).to eq(1)

      perform_enqueued_jobs do
        account_user.destroy!
      end

      expect(user.assigned_conversations.count).to eq(0)
    end
  end

  describe 'unread filter count invalidation' do
    let(:notifier) { instance_double(Conversations::UnreadCounts::UserFilterNotifier, perform: true) }

    before do
      allow(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).and_return(notifier)
    end

    it 'notifies when the account role changes' do
      account_user.update!(role: :administrator)

      expect(Conversations::UnreadCounts::UserFilterNotifier).to have_received(:new).with(
        account: account_user.account,
        user: account_user.user
      )
      expect(notifier).to have_received(:perform)
    end

    it 'notifies when account access is removed' do
      expect(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).with(
        account: account_user.account,
        user: account_user.user
      ).and_return(notifier)
      expect(notifier).to receive(:perform)

      account_user.destroy!
    end
  end
end
