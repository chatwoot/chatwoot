# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InternalChat::Limits do
  describe '.unlimited?' do
    it 'returns true' do
      expect(described_class.unlimited?).to be true
    end
  end

  describe '.polls_enabled?' do
    it 'returns true' do
      expect(described_class.polls_enabled?).to be true
    end
  end

  describe '.max_private_channels' do
    it 'returns nil (no limit)' do
      expect(described_class.max_private_channels).to be_nil
    end
  end

  describe '.search_history_days' do
    it 'returns nil (full history)' do
      expect(described_class.search_history_days).to be_nil
    end
  end
end
