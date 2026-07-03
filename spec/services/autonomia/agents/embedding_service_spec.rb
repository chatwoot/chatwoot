require 'rails_helper'

RSpec.describe Autonomia::Agents::EmbeddingService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }

  describe 'model resolution (B1)' do
    it 'reads the active model from Config (single source of truth)' do
      allow(Autonomia::Agents::Config).to receive(:active_embedding_model).and_return('text-embedding-3-large')
      expect(described_class.new(account: account).instance_variable_get(:@model)).to eq('text-embedding-3-large')
    end
  end

  describe '#embed_batch (B1 — real batching)' do
    let(:ctx) { instance_double(RubyLLM::Context) }

    # `context` é o seam do provider externo (RubyLLM) — stubar é o ponto de isolamento correto.
    before { allow(service).to receive(:context).and_return(ctx) } # rubocop:disable RSpec/SubjectStub

    it 'makes ONE call per batch with array input and aligns 1:1, blanks -> []' do
      # Arrange — só os não-vazios vão à API, em um único request
      expect(ctx).to receive(:embed).once.with(%w[a b], model: anything)
                                    .and_return(instance_double(RubyLLM::Embedding, vectors: [[1.0], [2.0]]))

      # Act
      result = service.embed_batch(['a', '', 'b'])

      # Assert — vazio preserva a posição como []
      expect(result).to eq([[1.0], [], [2.0]])
    end

    it 'splits into slices of EMBED_BATCH_SIZE' do
      # Arrange
      size = described_class::EMBED_BATCH_SIZE
      texts = Array.new(size + 10) { |i| "t#{i}" }
      allow(ctx).to receive(:embed).and_return(
        instance_double(RubyLLM::Embedding, vectors: Array.new(size) { [0.0] }),
        instance_double(RubyLLM::Embedding, vectors: Array.new(10) { [0.0] })
      )

      # Act
      result = service.embed_batch(texts)

      # Assert — dois requests (size + 10), saída alinhada 1:1
      expect(ctx).to have_received(:embed).twice
      expect(result.size).to eq(texts.size)
    end

    it 'normalizes a single flat vector into an array-of-arrays' do
      # Arrange — provider devolve vetor único (flat) p/ input de 1
      allow(ctx).to receive(:embed).and_return(instance_double(RubyLLM::Embedding, vectors: [1.0, 2.0, 3.0]))

      # Act
      result = service.embed_batch(['solo'])

      # Assert
      expect(result).to eq([[1.0, 2.0, 3.0]])
    end

    it 'returns [] for a blank-only list without calling the API' do
      # Assert
      expect(ctx).not_to receive(:embed)
      expect(service.embed_batch(['', nil])).to eq([[], []])
    end
  end
end
