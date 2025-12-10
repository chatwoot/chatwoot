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

  describe 'responsible associations' do
    let!(:responsible) { create(:account_user, account: account_user.account) }

    it 'allows setting a responsible' do
      account_user.responsible = responsible
      expect(account_user.save).to be(true)
      expect(account_user.responsible).to eq(responsible)
    end

    it 'allows accessing subordinates' do
      account_user.responsible = responsible
      account_user.save!
      expect(responsible.subordinates).to include(account_user)
    end

    it 'nullifies subordinates when responsible is destroyed' do
      account_user.responsible = responsible
      account_user.save!
      responsible.destroy!
      account_user.reload
      expect(account_user.responsible_id).to be_nil
    end
  end

  describe 'responsible validations' do
    context 'when trying to assign self as responsible' do
      it 'does not allow self-assignment' do
        account_user.responsible = account_user
        expect(account_user.valid?).to be(false)
        expect(account_user.errors[:responsible_id]).to include('cannot be yourself')
      end
    end

    context 'when trying to assign responsible from different account' do
      it 'does not allow responsible from different account' do
        other_account = create(:account)
        other_account_user = create(:account_user, account: other_account)
        account_user.responsible = other_account_user
        expect(account_user.valid?).to be(false)
        expect(account_user.errors[:responsible_id]).to include('must be from the same account')
      end
    end

    context 'when assigning responsible from same account' do
      it 'allows responsible from same account' do
        same_account_user = create(:account_user, account: account_user.account)
        account_user.responsible = same_account_user
        expect(account_user.valid?).to be(true)
      end
    end
  end
end
