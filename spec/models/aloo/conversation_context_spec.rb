# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::ConversationContext do
  subject(:context) { build(:aloo_conversation_context) }

  describe 'associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
  end

  describe 'delegation' do
    let(:account) { create(:account) }
    let(:assistant) { create(:aloo_assistant, account: account) }
    let(:context) { create(:aloo_conversation_context, assistant: assistant) }

    it 'delegates account to assistant' do
      expect(context.account).to eq(account)
    end

    it 'delegates account_id to assistant' do
      expect(context.account_id).to eq(account.id)
    end
  end

  describe '#track_message!' do
    let(:context) { create(:aloo_conversation_context, message_count: 0, input_tokens: 0, output_tokens: 0, total_cost: 0) }

    it 'increments message_count' do
      expect { context.track_message!(input_tokens: 100, output_tokens: 50, cost: 0.001) }
        .to change { context.message_count }.by(1)
    end

    it 'accumulates token counts' do
      context.track_message!(input_tokens: 100, output_tokens: 50, cost: 0)

      expect(context.input_tokens).to eq(100)
      expect(context.output_tokens).to eq(50)
    end

    it 'accumulates cost' do
      context.track_message!(input_tokens: 100, output_tokens: 50, cost: 0.001)
      context.track_message!(input_tokens: 100, output_tokens: 50, cost: 0.001)

      expect(context.total_cost).to eq(0.002)
    end

    it 'persists changes' do
      context.track_message!(input_tokens: 100, output_tokens: 50, cost: 0.001)

      expect(context.reload.message_count).to eq(1)
    end
  end

  describe '#record_tool_call!' do
    let(:context) { create(:aloo_conversation_context, tool_history: []) }

    it 'appends to tool_history' do
      context.record_tool_call!(
        tool_name: 'faq_lookup',
        input: { query: 'test' },
        output: { results: [] },
        success: true
      )

      expect(context.tool_history.size).to eq(1)
      expect(context.tool_history.first['tool']).to eq('faq_lookup')
    end

    it 'includes timestamp' do
      freeze_time do
        context.record_tool_call!(
          tool_name: 'handoff',
          input: {},
          output: {},
          success: true
        )

        expect(context.tool_history.first['timestamp']).to eq(Time.current.iso8601)
      end
    end

    it 'records success status' do
      context.record_tool_call!(tool_name: 'test', input: {}, output: {}, success: false)

      expect(context.tool_history.first['success']).to be false
    end
  end

  describe '#get_context' do
    let(:context) { create(:aloo_conversation_context, :with_context_data) }

    it 'retrieves value from context_data' do
      expect(context.get_context('memory_extraction_completed')).to be true
    end

    it 'returns nil for missing key' do
      expect(context.get_context('nonexistent')).to be_nil
    end

    it 'works with symbol keys' do
      expect(context.get_context(:last_topic)).to eq('billing')
    end
  end

  describe '#set_context' do
    let(:context) { create(:aloo_conversation_context) }

    it 'stores value in context_data' do
      context.set_context('custom_key', 'custom_value')

      expect(context.context_data['custom_key']).to eq('custom_value')
    end

    it 'persists changes' do
      context.set_context('persisted_key', 'persisted_value')

      expect(context.reload.context_data['persisted_key']).to eq('persisted_value')
    end
  end

  describe '#total_tokens' do
    let(:context) { build(:aloo_conversation_context, input_tokens: 100, output_tokens: 50) }

    it 'sums input and output tokens' do
      expect(context.total_tokens).to eq(150)
    end
  end

  describe '#context_overflow?' do
    context 'when message_count exceeds max' do
      let(:context) { build(:aloo_conversation_context, :overflow) }

      it 'returns true' do
        expect(context.context_overflow?).to be true
      end
    end

    context 'when within limit' do
      let(:context) { build(:aloo_conversation_context, message_count: 10) }

      it 'returns false' do
        expect(context.context_overflow?).to be false
      end
    end

    it 'respects custom max parameter' do
      context = build(:aloo_conversation_context, message_count: 25)

      expect(context.context_overflow?(max_messages: 20)).to be true
      expect(context.context_overflow?(max_messages: 30)).to be false
    end
  end

  describe '#recent_tools' do
    let(:context) { create(:aloo_conversation_context, :with_multiple_tools) }

    it 'returns last N tool calls' do
      recent = context.recent_tools(limit: 1)

      expect(recent.size).to eq(1)
      expect(recent.first['tool']).to eq('handoff')
    end

    it 'defaults to 5' do
      # Add more tools
      5.times do |i|
        context.tool_history << { 'tool' => "tool_#{i}", 'timestamp' => Time.current.iso8601 }
      end
      context.save!

      expect(context.recent_tools.size).to eq(5)
    end
  end

  describe '#reset!' do
    let(:context) { create(:aloo_conversation_context, :high_usage, :with_context_data, :with_tool_history) }

    it 'clears all tracking data' do
      context.reset!

      expect(context.context_data).to eq({})
      expect(context.tool_history).to eq([])
      expect(context.message_count).to eq(0)
      expect(context.input_tokens).to eq(0)
      expect(context.output_tokens).to eq(0)
      expect(context.total_cost).to eq(0)
    end
  end
end
