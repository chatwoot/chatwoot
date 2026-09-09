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

  describe 'validations' do
    it 'allows nil' do
      account_user.active_chat_limit = nil
      expect(account_user).to be_valid
    end

    it 'allows 0' do
      account_user.active_chat_limit = 0
      expect(account_user).to be_valid
    end

    it 'allows positive numbers' do
      account_user.active_chat_limit = 5
      expect(account_user).to be_valid
    end

    it 'does NOT allow negative numbers' do
      account_user.active_chat_limit = -1
      expect(account_user).not_to be_valid
    end
  end

  describe '#active_chat_limit_enabled?' do
    it 'returns true when active_chat_limit_enabled is true' do
      account_user.active_chat_limit_enabled = true
      expect(account_user.active_chat_limit_enabled?).to be(true)
    end

    it 'returns false when active_chat_limit_enabled is false' do
      account_user.active_chat_limit_enabled = false
      expect(account_user.active_chat_limit_enabled?).to be(false)
    end
  end

  describe 'callbacks' do
    describe 'after_commit :process_queue_when_agent_available' do
      let!(:account) { create(:account, queue_enabled: true) }
      let!(:user) { create(:user, account: account) }
      let!(:account_user) { user.account_users.first }

      before do
        allow(account_user).to receive(:online?).and_return(true)
      end

      it 'enqueues ProcessQueueJob when availability changed and agent is online' do
        account.inboxes.destroy_all

        create(:inbox, account: account)
        create(:inbox, account: account)

        expect(account.inboxes.count).to eq(2)

        account_user.update!(availability: 'offline')

        expect do
          account_user.update!(availability: 'online')
        end.to have_enqueued_job(Queue::ProcessQueueJob).exactly(2).times
      end

      it 'does NOT enqueue job when queue is disabled' do
        create(:inbox, account: account)
        create(:inbox, account: account)

        account.update(queue_enabled: false)

        expect do
          account_user.update!(availability: 'online')
        end.not_to have_enqueued_job(Queue::ProcessQueueJob)
      end

      it 'does NOT enqueue job when agent is not online' do
        create(:inbox, account: account)
        create(:inbox, account: account)

        allow(account_user).to receive(:online?).and_return(false)

        expect do
          account_user.update!(availability: 'online')
        end.not_to have_enqueued_job(Queue::ProcessQueueJob)
      end
    end
  end

  describe 'filtered unread count invalidation' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:invalidator) { instance_double(Conversations::UnreadCounts::FilteredCountInvalidator, user_visibility_changed!: true) }

    before do
      allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).and_return(invalidator)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'invalidates filtered counts when the user is added to an account' do
      create(:account_user, account: account, user: user)

      expect(invalidator).to have_received(:user_visibility_changed!).with(user_id: user.id)
    end

    it 'invalidates filtered counts when the user role changes' do
      account_user = create(:account_user, account: account, user: user)

      account_user.update!(role: :administrator)

      expect(invalidator).to have_received(:user_visibility_changed!).with(user_id: user.id).twice
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        'account.cache_invalidated',
        kind_of(Time),
        account: account,
        cache_keys: account.cache_keys
      )
    end

    it 'invalidates filtered counts when the user is removed from an account' do
      account_user = create(:account_user, account: account, user: user)

      account_user.destroy!

      expect(invalidator).to have_received(:user_visibility_changed!).with(user_id: user.id).twice
    end
  end
end
