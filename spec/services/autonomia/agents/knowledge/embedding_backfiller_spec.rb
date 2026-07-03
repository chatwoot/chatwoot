require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::EmbeddingBackfiller do
  let(:account) { create(:account) }
  let(:agent) do
    Autonomia::Agents::Agent.create!(account: account, name: 'Bot', agent_type: 'support')
  end
  let(:embedder) { instance_double(Autonomia::Agents::EmbeddingService) }
  let(:large_vector) { Array.new(3072, 0.01) }

  def entry(content:, embedding: Array.new(1536, 0.1))
    agent.knowledge_entries.create!(
      account: account, content: content, status: :ready, chunk_index: 0, metadata: {}, embedding: embedding
    )
  end

  def large_populated?(record)
    Autonomia::Agents::KnowledgeEntry.where(id: record.id).where.not(embedding_large: nil).exists?
  end

  before do
    allow(Autonomia::Agents::EmbeddingService).to receive(:new).and_return(embedder)
    allow(embedder).to receive(:embed_batch) { |texts| texts.map { large_vector } }
  end

  describe '#perform' do
    it 'fills embedding_large (halfvec) for existing entries and leaves the legacy embedding intact' do
      # Arrange
      record = entry(content: 'frete grátis acima de R$200')

      # Act
      result = described_class.new.perform

      # Assert — grava large, NÃO apaga a coluna 3-small (sem regressão), conta o embedado
      expect(large_populated?(record)).to be(true)
      expect(record.reload.read_attribute(:embedding)).to be_present
      expect(result.embedded).to eq(1)
    end

    it 'requests the large model explicitly (independent of the global config)' do
      # Arrange
      entry(content: 'algum conteúdo')

      # Assert
      expect(Autonomia::Agents::EmbeddingService).to receive(:new)
        .with(account: account, model: Autonomia::Agents::Config::EMBEDDING_MODEL_LARGE).and_return(embedder)

      # Act
      described_class.new.perform
    end

    it 'is idempotent — a second run re-embeds nothing (only NULL embedding_large is touched)' do
      # Arrange
      entry(content: 'conteúdo')
      described_class.new.perform

      # Act
      second = described_class.new.perform

      # Assert
      expect(second.embedded).to eq(0)
    end

    it 'skips entries whose embedding comes back blank (never writes an empty vector)' do
      # Arrange
      entry(content: 'sem vetor')
      allow(embedder).to receive(:embed_batch) { |texts| texts.map { [] } }

      # Act
      result = described_class.new.perform

      # Assert
      expect(result.embedded).to eq(0)
      expect(result.skipped).to eq(1)
    end

    it 'skips an account (does not abort) when its embedding credential/provider fails' do
      # Arrange
      record = entry(content: 'conteúdo')
      allow(embedder).to receive(:embed_batch)
        .and_raise(Autonomia::Agents::EmbeddingService::EmbeddingError, 'ai_not_configured')

      # Act
      result = described_class.new.perform

      # Assert — a conta falha é registrada, nada é gravado, o backfill não explode
      expect(result.failed_accounts).to eq([account.id])
      expect(large_populated?(record)).to be(false)
    end

    it 'restricts to the given account_ids when provided' do
      # Arrange
      entry(content: 'conteúdo')
      other = create(:account)

      # Act
      result = described_class.new(account_ids: [other.id]).perform

      # Assert — a conta fora do filtro não é percorrida
      expect(result.accounts).to eq(0)
    end
  end
end
