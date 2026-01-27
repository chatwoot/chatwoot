# frozen_string_literal: true

RSpec.shared_examples 'embeddable' do
  describe 'Aloo::Embeddable concern' do
    it { is_expected.to respond_to(:embedding) }
    it { is_expected.to respond_to(:embedding_content) }
    it { is_expected.to respond_to(:embedded?) }
    it { is_expected.to respond_to(:generate_embedding!) }
    it { is_expected.to respond_to(:similarity_to) }

    describe 'scopes' do
      describe '.with_embedding' do
        it 'returns records with embedding' do
          record_with = create(described_class.model_name.singular.to_sym, embedding: Array.new(1536) { 0.0 })
          record_without = create(described_class.model_name.singular.to_sym, embedding: nil)

          result = described_class.with_embedding

          expect(result).to include(record_with)
          expect(result).not_to include(record_without)
        end
      end

      describe '.without_embedding' do
        it 'returns records without embedding' do
          record_with = create(described_class.model_name.singular.to_sym, embedding: Array.new(1536) { 0.0 })
          record_without = create(described_class.model_name.singular.to_sym, embedding: nil)

          result = described_class.without_embedding

          expect(result).not_to include(record_with)
          expect(result).to include(record_without)
        end
      end
    end

    describe '#embedded?' do
      it 'returns true when embedding present' do
        subject.embedding = Array.new(1536) { 0.0 }
        expect(subject.embedded?).to be true
      end

      it 'returns false when embedding blank' do
        subject.embedding = nil
        expect(subject.embedded?).to be false
      end
    end

    describe '#generate_embedding!' do
      let(:mock_vector) { Array.new(1536) { rand(-1.0..1.0) } }
      let(:mock_embedder_result) { double('Embedder::Result', vector: mock_vector, success?: true) }
      let(:document_embedder_class) { double('DocumentEmbedder') }

      before do
        stub_const('Embedders::DocumentEmbedder', document_embedder_class)
        allow(document_embedder_class).to receive(:call).and_return(mock_embedder_result)
      end

      it 'calls DocumentEmbedder with embedding_content' do
        content = subject.embedding_content
        subject.generate_embedding!

        expect(document_embedder_class).to have_received(:call).with(text: content, tenant: subject.account)
      end

      it 'stores the resulting vector' do
        subject.generate_embedding!
        expect(subject.embedding).to eq(mock_vector)
      end

      it 'does nothing when content is blank' do
        allow(subject).to receive(:embedding_content).and_return('')
        subject.generate_embedding!

        expect(document_embedder_class).not_to have_received(:call)
      end
    end
  end
end
