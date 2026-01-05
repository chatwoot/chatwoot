# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelsMcp, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'describes label management' do
      expect(described_class.description).to include('labels')
      expect(described_class.description).to include('Categorizing')
    end
  end

  describe '#execute' do
    let(:mcp) { described_class.new }

    context 'with add action' do
      it 'adds labels to conversation' do
        result = mcp.execute(action: 'add', labels: %w[billing urgent])

        expect(result[:success]).to be true
        expect(conversation.reload.label_list).to include('billing', 'urgent')
      end

      it 'adds labels to existing labels' do
        conversation.update_labels(%w[support])

        mcp.execute(action: 'add', labels: %w[billing])

        expect(conversation.reload.label_list).to include('support', 'billing')
      end

      it 'returns previous and current labels' do
        conversation.update_labels(%w[support])

        result = mcp.execute(action: 'add', labels: %w[billing])

        expect(result[:data][:previous_labels]).to eq(['support'])
        expect(result[:data][:current_labels]).to include('support', 'billing')
      end
    end

    context 'with remove action' do
      before do
        conversation.update_labels(%w[billing support urgent])
      end

      it 'removes specified labels' do
        result = mcp.execute(action: 'remove', labels: %w[billing urgent])

        expect(result[:success]).to be true
        expect(conversation.reload.label_list).to eq(['support'])
      end

      it 'ignores labels not present' do
        result = mcp.execute(action: 'remove', labels: %w[nonexistent])

        expect(result[:success]).to be true
        expect(conversation.reload.label_list).to include('billing', 'support', 'urgent')
      end
    end

    context 'with set action' do
      before do
        conversation.update_labels(%w[old_label])
      end

      it 'replaces all labels' do
        result = mcp.execute(action: 'set', labels: %w[new_label1 new_label2])

        expect(result[:success]).to be true
        expect(conversation.reload.label_list).to eq(%w[new_label1 new_label2])
      end

      it 'can set to empty' do
        result = mcp.execute(action: 'set', labels: [])

        expect(result[:success]).to be false
        expect(result[:error]).to include('empty')
      end
    end

    context 'with invalid action' do
      it 'returns error for invalid action' do
        result = mcp.execute(action: 'invalid', labels: %w[test])

        expect(result[:success]).to be false
        expect(result[:error]).to include('Invalid action')
        expect(result[:error]).to include('add, remove, set')
      end
    end

    context 'with empty labels' do
      it 'returns error for empty labels array' do
        result = mcp.execute(action: 'add', labels: [])

        expect(result[:success]).to be false
        expect(result[:error]).to include('empty')
      end
    end

    context 'with case normalization' do
      it 'normalizes action to lowercase' do
        result = mcp.execute(action: 'ADD', labels: %w[test])

        expect(result[:success]).to be true
      end

      it 'strips whitespace from action' do
        result = mcp.execute(action: '  add  ', labels: %w[test])

        expect(result[:success]).to be true
      end

      it 'strips whitespace from labels' do
        mcp.execute(action: 'add', labels: ['  test  ', '  label  '])

        expect(conversation.reload.label_list).to include('test', 'label')
      end
    end

    context 'tracking execution' do
      it 'tracks in conversation context' do
        mcp.execute(action: 'add', labels: %w[test])

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.tool_history).not_to be_empty
        expect(context.tool_history.last['tool']).to eq('labels')
      end

      it 'logs execution' do
        expect_any_instance_of(described_class).to receive(:log_execution)
          .with(hash_including(action: 'add', labels: %w[test]), anything)

        mcp.execute(action: 'add', labels: %w[test])
      end
    end

    context 'when error occurs' do
      before do
        allow(conversation).to receive(:add_labels).and_raise(StandardError, 'DB error')
      end

      it 'returns error response' do
        result = mcp.execute(action: 'add', labels: %w[test])

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to update labels')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.conversation = nil
      end

      it 'returns error response' do
        result = mcp.execute(action: 'add', labels: %w[test])

        expect(result[:success]).to be false
        expect(result[:error]).to include('Conversation context required')
      end
    end
  end
end
