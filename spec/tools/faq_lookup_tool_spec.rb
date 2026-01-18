# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FaqLookupTool, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:contact) { conversation.contact }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
    Aloo::Current.contact = contact
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'indicates the tool is deprecated' do
      expect(described_class.description).to include('DEPRECATED')
    end

    it 'describes the tool purpose' do
      expect(described_class.description).to include('knowledge base')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }
    let(:knowledge_tool) { instance_double(KnowledgeLookupTool) }

    before do
      allow(KnowledgeLookupTool).to receive(:new).and_return(knowledge_tool)
      allow(knowledge_tool).to receive(:execute).and_return({ success: true, results: [] })
    end

    it 'logs deprecation warning' do
      expect(Rails.logger).to receive(:warn).with(/DEPRECATED.*FaqLookupTool/)

      tool.execute(query: 'test', search_type: 'knowledge')
    end

    context 'when search_type is "knowledge"' do
      it 'searches knowledge base via KnowledgeLookupTool' do
        expect(knowledge_tool).to receive(:execute).with(query: 'return policy')

        tool.execute(query: 'return policy', search_type: 'knowledge')
      end

      it 'formats results correctly' do
        allow(knowledge_tool).to receive(:execute).and_return({
                                                                success: true,
                                                                results: [
                                                                  { document_title: 'Policy', content: 'Return in 30 days' }
                                                                ]
                                                              })

        result = tool.execute(query: 'test', search_type: 'knowledge')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Knowledge Base Results')
      end
    end

    context 'when no results found' do
      it 'returns appropriate message' do
        result = tool.execute(query: 'nonexistent topic', search_type: 'knowledge')

        expect(result[:success]).to be true
        expect(result[:message]).to include('No relevant information found')
      end
    end

    context 'when error occurs' do
      before do
        allow(knowledge_tool).to receive(:execute).and_raise(StandardError, 'Search failed')
      end

      it 'returns error response' do
        result = tool.execute(query: 'test', search_type: 'knowledge')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Search failed')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.account = nil
      end

      it 'raises error' do
        expect { tool.execute(query: 'test', search_type: 'knowledge') }.to raise_error('Account context required')
      end
    end
  end
end
