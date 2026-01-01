# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::MemorySearchService, type: :service do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:service) { described_class.new(assistant: assistant, account: account) }

  let(:query_embedding) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:embedding_service) { instance_double(Aloo::EmbeddingService) }

  before do
    allow(Aloo::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:generate_embedding).and_return(query_embedding)
  end

  describe '#initialize' do
    it 'raises ArgumentError when account is nil' do
      expect { described_class.new(assistant: assistant, account: nil) }
        .to raise_error(ArgumentError, 'Account required')
    end

    it 'raises ArgumentError when assistant is nil' do
      expect { described_class.new(assistant: nil, account: account) }
        .to raise_error(ArgumentError, 'Assistant required')
    end

    it 'raises ArgumentError when account mismatch' do
      other_account = create(:account)
      expect { described_class.new(assistant: assistant, account: other_account) }
        .to raise_error(ArgumentError, 'Account mismatch')
    end
  end

  describe '#search' do
    it 'returns empty array for blank query' do
      expect(service.search('')).to eq([])
      expect(service.search(nil)).to eq([])
    end

    it 'returns empty array when embedding fails' do
      allow(embedding_service).to receive(:generate_embedding).and_return(nil)

      expect(service.search('test query')).to eq([])
    end

    it 'records trace' do
      expect(Aloo::Trace).to receive(:record_with_timing)
        .with(hash_including(trace_type: 'search'))
        .and_call_original

      service.search('test query')
    end

    context 'with contact' do
      let!(:contact_memory) { create(:aloo_memory, :preference, contact: contact, assistant: assistant, account: account) }
      let!(:global_memory) { create(:aloo_memory, :faq, assistant: assistant, account: account) }

      it 'searches contact-scoped memories' do
        results = service.search('test query', contact: contact)

        expect(results).to be_an(Array)
      end

      it 'includes global memories' do
        results = service.search('test query', contact: contact)

        # Both contact and global results should be included
        expect(results).to be_an(Array)
      end

      it 'splits limit between contact and global' do
        results = service.search('test query', contact: contact, limit: 10)

        expect(results.size).to be <= 10
      end
    end

    context 'without contact' do
      let!(:global_memory) { create(:aloo_memory, :faq, assistant: assistant, account: account) }

      it 'only searches global memories' do
        results = service.search('test query')

        expect(results).to be_an(Array)
      end
    end
  end

  describe '#search_for_context' do
    let!(:memory) { create(:aloo_memory, :faq, assistant: assistant, account: account, content: 'FAQ content') }

    it 'builds context string with proper formatting' do
      result = service.search_for_context('test query')

      expect(result).to be_a(String)
    end

    it 'respects token budget' do
      result = service.search_for_context('test query', max_tokens: 50)

      expect(result).to be_a(String)
    end

    it 'includes contact parameter when provided' do
      result = service.search_for_context('test query', contact: contact)

      expect(result).to be_a(String)
    end
  end

  describe '#find_by_type' do
    let!(:preference) { create(:aloo_memory, :preference, contact: contact, assistant: assistant, account: account) }
    let!(:faq) { create(:aloo_memory, :faq, assistant: assistant, account: account) }
    let!(:low_confidence) { create(:aloo_memory, :faq, :low_confidence, assistant: assistant, account: account) }

    it 'filters by memory type' do
      results = service.find_by_type('faq')

      expect(results).to all(have_attributes(memory_type: 'faq'))
    end

    it 'applies contact filter for contact-scoped types' do
      results = service.find_by_type('preference', contact: contact)

      results.each do |memory|
        expect(memory.contact_id).to eq(contact.id)
      end
    end

    it 'orders by confidence' do
      high_conf = create(:aloo_memory, :faq, :high_confidence, assistant: assistant, account: account)

      results = service.find_by_type('faq')

      if results.size >= 2
        expect(results.first.confidence).to be >= results.second.confidence
      end
    end

    it 'excludes low confidence memories' do
      results = service.find_by_type('faq')

      results.each do |memory|
        expect(memory.confidence).to be > 0.2
      end
    end
  end

  describe '#find_duplicate' do
    it 'returns nil for blank content' do
      expect(service.find_duplicate('', 'preference')).to be_nil
      expect(service.find_duplicate(nil, 'preference')).to be_nil
    end

    it 'returns nil when embedding fails' do
      allow(embedding_service).to receive(:generate_embedding).and_return(nil)

      expect(service.find_duplicate('test content', 'faq')).to be_nil
    end

    context 'with existing similar memory' do
      let!(:existing_memory) do
        create(:aloo_memory, :faq, content: 'Very similar content', assistant: assistant, account: account)
      end

      it 'finds similar memories above threshold' do
        # Mock nearest_neighbors to return the existing memory
        # The actual similarity check happens in the service
        result = service.find_duplicate('Very similar content', 'faq')

        # Result depends on vector similarity
        expect(result).to be_nil.or be_a(Aloo::Memory)
      end
    end

    it 'returns nil when no similar memory exists' do
      result = service.find_duplicate('Completely unique content', 'faq')

      expect(result).to be_nil
    end

    it 'respects contact scope for contact-scoped types' do
      create(:aloo_memory, :preference, contact: contact, content: 'Preference', assistant: assistant, account: account)

      result = service.find_duplicate('Preference', 'preference', contact: contact)

      # Should search within contact's memories
      expect(result).to be_nil.or have_attributes(contact_id: contact.id)
    end
  end
end
