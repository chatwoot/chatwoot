require 'rails_helper'

RSpec.describe Conversations::AgentAccessService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:recently_resolved) do
    create(:conversation, account: account, assignee: agent, status: :resolved, created_at: 60.days.ago).tap do |conversation|
      conversation.update_columns(resolved_at: 1.day.ago) # rubocop:disable Rails/SkipsModelValidations
    end
  end
  let(:long_resolved) do
    create(:conversation, account: account, assignee: agent, status: :resolved, created_at: 60.days.ago).tap do |conversation|
      conversation.update_columns(resolved_at: 45.days.ago) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  describe '.apply_scope' do
    it 'limits resolved history by resolution time rather than creation time' do
      scoped = described_class.apply_scope(account.conversations, agent, account)

      expect(scoped).to include(recently_resolved)
      expect(scoped).not_to include(long_resolved)
    end
  end

  describe '#allowed?' do
    it 'allows a conversation resolved within the history window' do
      expect(described_class.new(conversation: recently_resolved, user: agent, account: account).allowed?).to be(true)
    end

    it 'denies a conversation resolved before the history window' do
      expect(described_class.new(conversation: long_resolved, user: agent, account: account).allowed?).to be(false)
    end
  end
end
