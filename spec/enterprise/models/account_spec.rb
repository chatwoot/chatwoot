# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  describe 'usage_limits' do
    before do
      create(:installation_config, name: 'ACCOUNT_AGENTS_LIMIT', value: 20)
    end

    let!(:account) { create(:account) }

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
  end
end
