# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  describe 'usage_limits' do
    before do
      create(:installation_config, name: 'ACCOUNT_AGENTS_LIMIT', value: 20)
    end

    let!(:account) { create(:account) }

    describe 'audit logs' do
      it 'returns audit logs' do
        # checking whether associated_audits method is present
        expect(account.associated_audits.present?).to be false
      end
    end

    it 'returns max limits from global config when enterprise version' do
      expect(account.usage_limits).to eq(
        {
          agents: 20,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns max limits from account when enterprise version' do
      account.update(limits: { agents: 10 })
      expect(account.usage_limits).to eq(
        {
          agents: 10,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns limits based on subscription' do
      account.update(limits: { agents: 10 }, custom_attributes: { subscribed_quantity: 5 })
      expect(account.usage_limits).to eq(
        {
          agents: 5,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns max limits from global config if account limit is absent' do
      account.update(limits: { agents: '' })
      expect(account.usage_limits).to eq(
        {
          agents: 20,
          inboxes: ChatwootApp.max_limit
        }
      )
    end

    it 'returns max limits from app limit if account limit and installation config is absent' do
      account.update(limits: { agents: '' })
      InstallationConfig.where(name: 'ACCOUNT_AGENTS_LIMIT').update(value: '')

      expect(account.usage_limits).to eq(
        {
          agents: ChatwootApp.max_limit,
          inboxes: ChatwootApp.max_limit
        }
      )
    end
  end
end
