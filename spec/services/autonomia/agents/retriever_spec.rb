require 'rails_helper'

RSpec.describe Autonomia::Agents::Retriever do
  let(:account) { create(:account) }

  let(:agent) do
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Bot', agent_type: 'custom', status: :active, enabled: true,
      instruction: 'Atenda o cliente.'
    )
  end

  describe 'query cap before embedding (C1)' do
    let(:embedding_service) { instance_double(Autonomia::Agents::EmbeddingService) }
    let(:embedded_texts) { [] }

    before do
      allow(embedding_service).to receive(:embed) do |text|
        embedded_texts << text
        [] # vetor vazio -> retrieve devolve [] sem tocar o banco
      end
      allow(Autonomia::Agents::EmbeddingService).to receive(:new).and_return(embedding_service)
    end

    it 'sends the embedding service a truncated query, never the raw oversized text' do
      # Arrange
      query = 'a' * (Autonomia::Agents::Config::MAX_QUERY_CHARS + 5_000)

      # Act
      result = described_class.new(agent: agent).retrieve(query)

      # Assert
      expect(result).to eq([])
      expect(embedded_texts.size).to eq(1)
      expect(embedded_texts.first.length).to eq(Autonomia::Agents::Config::MAX_QUERY_CHARS)
      expect(embedded_texts.first).to end_with(Autonomia::Agents::Config::TRUNCATION_SUFFIX)
      expect(embedded_texts.first).to start_with('aaa')
    end

    it 'embeds a query within the cap untouched' do
      # Arrange
      query = 'qual o horário de atendimento?'

      # Act
      described_class.new(agent: agent).retrieve(query)

      # Assert
      expect(embedded_texts).to eq([query])
    end
  end

  # B1 — modelo 3-large ativo: NN pela coluna halfvec `embedding_large` (SQL cru), não pela gem
  # neighbor sobre :embedding. Prova end-to-end do caminho grande no banco real (halfvec 3072 + hnsw).
  describe 'large embedding path (3-large / halfvec)' do
    let(:embedding_service) { instance_double(Autonomia::Agents::EmbeddingService) }
    let(:query_vector) { Array.new(3072) { 0.01 } }

    before do
      allow(Autonomia::Agents::Config).to receive(:embedding_large?).and_return(true)
      allow(embedding_service).to receive(:embed).and_return(query_vector)
      allow(Autonomia::Agents::EmbeddingService).to receive(:new).and_return(embedding_service)
    end

    def create_large_entry(content, vector)
      entry = agent.knowledge_entries.create!(
        account: account, content: content, status: :ready, chunk_index: 0, metadata: {}
      )
      # update_all: escrita direta do halfvec de teste (mesmo caminho do Ingestor).
      agent.knowledge_entries.where(id: entry.id)
           .update_all(['embedding_large = ?::halfvec', "[#{vector.join(',')}]"]) # rubocop:disable Rails/SkipsModelValidations
      entry
    end

    it 'retrieves entries via the halfvec column and exposes neighbor_distance' do
      # Arrange — chunk com embedding_large idêntico à query (distância de cosseno ~0, abaixo do teto)
      entry = create_large_entry('frete grátis acima de R$200', query_vector)

      # Act
      result = described_class.new(agent: agent).retrieve('frete')

      # Assert
      expect(result.map(&:id)).to include(entry.id)
      expect(result.first.neighbor_distance.to_f).to be <= Autonomia::Agents::Config::RETRIEVAL_HARD_CEILING
    end

    it 'ignores rows not yet backfilled (embedding_large IS NULL)' do
      # Arrange — entry só com a coluna legada, sem embedding_large
      agent.knowledge_entries.create!(
        account: account, content: 'ainda não reprocessado', status: :ready, chunk_index: 0, metadata: {}
      )

      # Act
      result = described_class.new(agent: agent).retrieve('reprocessado')

      # Assert
      expect(result).to eq([])
    end
  end
end
