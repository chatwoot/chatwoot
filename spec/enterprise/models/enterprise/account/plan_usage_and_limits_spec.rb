# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enterprise::Account::PlanUsageAndLimits do
  let(:account) { create(:account) }

  describe '#increment_response_usage' do
    it 'increments usage by 1 by default' do
      initial_usage = account.custom_attributes['captain_responses_usage'].to_i
      account.increment_response_usage
      account.reload
      expect(account.custom_attributes['captain_responses_usage']).to eq(initial_usage + 1)
    end

    it 'increments usage by the specified credits' do
      initial_usage = account.custom_attributes['captain_responses_usage'].to_i
      account.increment_response_usage(credits: 3)
      account.reload
      expect(account.custom_attributes['captain_responses_usage']).to eq(initial_usage + 3)
    end

    it 'handles zero initial usage' do
      account.custom_attributes['captain_responses_usage'] = nil
      account.save!
      account.increment_response_usage(credits: 2)
      account.reload
      expect(account.custom_attributes['captain_responses_usage']).to eq(2)
    end
  end
end
