# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemoryLookupTool, :aloo do
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
    it 'describes the tool purpose' do
      expect(described_class.description).to include('memories')
      expect(described_class.description).to include('customer preferences')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }
    let(:memory_service) { instance_double(Aloo::MemorySearchService) }

    before do
      allow(Aloo::MemorySearchService).to receive(:new).and_return(memory_service)
      allow(memory_service).to receive(:search).and_return([])
    end

    it 'searches memories with contact by default' do
      expect(memory_service).to receive(:search).with('preferences', contact: contact, limit: 5)

      tool.execute(query: 'preferences')
    end

    it 'excludes customer context when requested' do
      expect(memory_service).to receive(:search).with('general', contact: nil, limit: 5)

      tool.execute(query: 'general', include_customer_context: false)
    end

    context 'with results' do
      before do
        allow(memory_service).to receive(:search).and_return([
                                                               { memory_type: 'preference', content: 'Prefers email', is_contact_scoped: true },
                                                               { memory_type: 'fact', content: 'Premium customer', is_contact_scoped: false }
                                                             ])
      end

      it 'formats results with scope indicator' do
        result = tool.execute(query: 'customer')

        expect(result[:success]).to be true
        expect(result[:message]).to include('Relevant Memories')
        expect(result[:message]).to include('Customer-specific')
        expect(result[:message]).to include('General')
      end
    end

    context 'with no results' do
      it 'returns appropriate message' do
        result = tool.execute(query: 'unknown')

        expect(result[:success]).to be true
        expect(result[:message]).to include('No relevant memories found')
      end
    end

    context 'when error occurs' do
      before do
        allow(memory_service).to receive(:search).and_raise(StandardError, 'Memory error')
      end

      it 'logs execution with error' do
        expect_any_instance_of(described_class).to receive(:log_execution)
          .with(anything, anything, success: false, error_message: 'Memory error')

        tool.execute(query: 'test')
      end

      it 'returns error response' do
        result = tool.execute(query: 'test')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Memory search failed')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.account = nil
      end

      it 'raises error' do
        expect { tool.execute(query: 'test') }.to raise_error('Account context required')
      end
    end
  end
end
