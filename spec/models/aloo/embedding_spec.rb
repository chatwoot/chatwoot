# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/support/shared_examples/aloo/embeddable')

RSpec.describe Aloo::Embedding do
  subject(:embedding) { build(:aloo_embedding) }

  describe 'concerns' do
    it 'includes AccountScoped' do
      expect(described_class.ancestors).to include(Aloo::AccountScoped)
    end

    it 'includes Embeddable' do
      expect(described_class.ancestors).to include(Aloo::Embeddable)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
    it { is_expected.to belong_to(:document).class_name('Aloo::Document').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'scopes' do
    describe '.for_search' do
      let!(:with_embedding) { create(:aloo_embedding) }
      let!(:without_embedding) { create(:aloo_embedding, :without_embedding) }

      it 'returns embeddings with embedding vector' do
        expect(described_class.for_search).to include(with_embedding)
        expect(described_class.for_search).not_to include(without_embedding)
      end
    end

    describe '.with_question' do
      let!(:faq_embedding) { create(:aloo_embedding, :faq_format) }
      let!(:regular_embedding) { create(:aloo_embedding, question: nil) }

      it 'returns embeddings with question field' do
        expect(described_class.with_question).to include(faq_embedding)
        expect(described_class.with_question).not_to include(regular_embedding)
      end
    end
  end

  describe '#embedding_content' do
    context 'when question is present' do
      it 'combines question and answer' do
        embedding.question = 'What is the return policy?'
        embedding.content = 'You can return items within 30 days.'

        expect(embedding.embedding_content).to eq("Q: What is the return policy?\nA: You can return items within 30 days.")
      end
    end

    context 'when question is blank' do
      it 'returns content only' do
        embedding.question = nil
        embedding.content = 'Some content'

        expect(embedding.embedding_content).to eq('Some content')
      end
    end
  end

  describe '#to_context_format' do
    context 'with question' do
      it 'formats as Q&A' do
        embedding.question = 'How do I reset?'
        embedding.content = 'Click the reset button.'

        expect(embedding.to_context_format).to eq("Q: How do I reset?\nA: Click the reset button.")
      end
    end

    context 'without question' do
      it 'returns content' do
        embedding.question = nil
        embedding.content = 'Documentation content'

        expect(embedding.to_context_format).to eq('Documentation content')
      end
    end
  end

  describe '#source_info' do
    let(:document) { create(:aloo_document, title: 'User Guide', source_url: 'https://example.com/guide') }
    let(:embedding) { create(:aloo_embedding, document: document, metadata: { 'chunk_index' => 5 }) }

    it 'returns document metadata' do
      info = embedding.source_info

      expect(info[:document_title]).to eq('User Guide')
      expect(info[:document_url]).to eq('https://example.com/guide')
      expect(info[:chunk_index]).to eq(5)
    end

    context 'without document' do
      let(:embedding) { create(:aloo_embedding, :without_document) }

      it 'returns nil for document fields' do
        info = embedding.source_info

        expect(info[:document_title]).to be_nil
        expect(info[:document_url]).to be_nil
      end
    end
  end
end
