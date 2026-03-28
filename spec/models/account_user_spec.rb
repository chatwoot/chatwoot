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

    it 'includes participating_only flag when enabled' do
      account_user.update!(participating_only: true)
      expect(account_user.permissions).to include('participating_only')
      expect(account_user.permissions).to eq(%w[agent participating_only])
    end

    it 'does not include participating_only flag for administrators' do
      account_user.administrator!
      account_user.update!(participating_only: true)
      expect(account_user.permissions).to eq(['administrator'])
      expect(account_user.permissions).not_to include('participating_only')
    end
  end

  describe '#participating_only?' do
    it 'returns false by default' do
      expect(account_user.participating_only?).to be(false)
    end

    it 'returns true when enabled for agent' do
      account_user.update!(participating_only: true)
      expect(account_user.participating_only?).to be(true)
    end

    it 'returns false for administrators even when flag is set' do
      account_user.administrator!
      account_user.update!(participating_only: true)
      expect(account_user.participating_only?).to be(false)
    end
  end

  describe '#restricted_conversation_access?' do
    it 'returns true when participating_only is enabled' do
      account_user.update!(participating_only: true)
      expect(account_user.restricted_conversation_access?).to be(true)
    end

    it 'returns false when participating_only is disabled' do
      expect(account_user.restricted_conversation_access?).to be(false)
    end

    it 'returns false for administrators' do
      account_user.administrator!
      account_user.update!(participating_only: true)
      expect(account_user.restricted_conversation_access?).to be(false)
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
end
