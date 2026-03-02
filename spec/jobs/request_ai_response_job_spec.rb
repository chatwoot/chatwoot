# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestAiResponseJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:ai_agent) { create(:user, account: account) }
  let(:message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Hello') }

  before do
    allow(ai_agent).to receive(:is_ai?).and_return(true)
    allow(ai_agent).to receive(:human_agent).and_return(nil)
    conversation.update!(assignee: ai_agent)
    allow(Redis::Alfred).to receive(:set).and_return(true)
    allow(Redis::Alfred).to receive(:delete)
  end

  describe 'Redis dedup lock namespace' do
    it 'uses the shared ai_response_lock: key namespace with message id' do
      described_class.new.perform(message)

      expected_key = "ai_response_lock:msg_#{message.id}"
      expect(Redis::Alfred).to have_received(:set).with(expected_key, anything, nx: true, ex: 300)
    end

    it 'uses source_id in the shared lock key when present' do
      message.update!(source_id: 'wamid.xyz789')

      described_class.new.perform(message)

      expect(Redis::Alfred).to have_received(:set).with('ai_response_lock:wamid.xyz789', anything, nx: true, ex: 300)
    end

    it 'skips processing when another AI system holds the lock' do
      allow(Redis::Alfred).to receive(:set).and_return(false)

      expect do
        described_class.new.perform(message)
      end.not_to(change { conversation.messages.where(message_type: :outgoing).count })
    end
  end

  describe 'cross-system dedup with Aloo::ResponseJob' do
    it 'uses the same lock key namespace as Aloo::ResponseJob' do
      described_class.new.perform(message)

      # Both jobs must use "ai_response_lock:" prefix so whichever runs first wins
      expected_key = "ai_response_lock:msg_#{message.id}"
      expect(Redis::Alfred).to have_received(:set).with(expected_key, anything, hash_including(nx: true))
    end
  end
end
