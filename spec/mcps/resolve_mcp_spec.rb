# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResolveMcp, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'describes when to resolve' do
      expect(described_class.description).to include('Resolve')
      expect(described_class.description).to include('conversation')
    end
  end

  describe '#execute' do
    let(:mcp) { described_class.new }

    context 'with valid parameters' do
      it 'resolves the conversation' do
        mcp.execute(reason: 'Issue resolved')

        expect(conversation.reload.status).to eq('resolved')
      end

      it 'returns success response' do
        result = mcp.execute(reason: 'Issue resolved')

        expect(result[:success]).to be true
        expect(result[:data][:resolved]).to be true
      end

      it 'creates activity message with reason' do
        expect do
          mcp.execute(reason: 'Customer confirmed issue is fixed')
        end.to change { conversation.messages.where(private: false).count }.by(1)

        message = conversation.messages.where(private: false).last
        expect(message.content).to include('Conversation resolved by AI')
        expect(message.content).to include('Customer confirmed issue is fixed')
      end

      it 'tracks execution in conversation context' do
        mcp.execute(reason: 'Issue resolved')

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.tool_history).not_to be_empty
        expect(context.tool_history.last['tool']).to eq('resolve')
      end

      it 'logs execution' do
        expect_any_instance_of(described_class).to receive(:log_execution)
          .with(hash_including(reason: 'Test reason'), anything)

        mcp.execute(reason: 'Test reason')
      end
    end

    context 'with summary' do
      it 'adds summary as private note before resolving' do
        expect do
          mcp.execute(reason: 'Issue fixed', summary: 'Customer had billing question about subscription')
        end.to change { conversation.messages.where(private: true).count }.by(1)

        note = conversation.messages.where(private: true).last
        expect(note.content).to include('Conversation Summary')
        expect(note.content).to include('billing question about subscription')
      end

      it 'creates both summary note and activity message' do
        expect do
          mcp.execute(reason: 'Issue fixed', summary: 'Summary here')
        end.to change { conversation.messages.count }.by(2)
      end
    end

    context 'when already resolved' do
      before do
        conversation.update!(status: :resolved)
      end

      it 'returns error response' do
        result = mcp.execute(reason: 'Try to resolve again')

        expect(result[:success]).to be false
        expect(result[:error]).to include('already resolved')
      end

      it 'does not create messages' do
        expect do
          mcp.execute(reason: 'Try to resolve again')
        end.not_to(change { conversation.messages.count })
      end
    end

    context 'when error occurs' do
      before do
        allow(conversation).to receive(:resolved!).and_raise(StandardError, 'DB error')
      end

      it 'returns error response' do
        result = mcp.execute(reason: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to resolve conversation')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.conversation = nil
      end

      it 'returns error response' do
        result = mcp.execute(reason: 'Test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Conversation context required')
      end
    end
  end

  describe 'activity message attributes' do
    let(:mcp) { described_class.new }

    it 'sets message_type to activity' do
      mcp.execute(reason: 'Issue resolved')

      message = conversation.messages.where(private: false).last
      expect(message.message_type).to eq('activity')
    end

    it 'sets content_attributes with resolution marker' do
      mcp.execute(reason: 'Issue resolved')

      message = conversation.messages.where(private: false).last
      expect(message.content_attributes['aloo_resolved']).to be true
      expect(message.content_attributes['resolution_reason']).to eq('Issue resolved')
    end
  end

  describe 'summary note attributes' do
    let(:mcp) { described_class.new }

    it 'sets content_attributes with summary marker' do
      mcp.execute(reason: 'Issue resolved', summary: 'Test summary')

      note = conversation.messages.where(private: true).last
      expect(note.content_attributes['aloo_resolution_summary']).to be true
    end
  end
end
