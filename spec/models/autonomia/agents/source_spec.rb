require 'rails_helper'

RSpec.describe Autonomia::Agents::Source do
  let(:account) { create(:account) }
  let(:agent) do
    Autonomia::Agents::Agent.create!(account: account, name: 'Agente Teste', agent_type: 'support')
  end
  let(:embedding_vector) { [1.0] + Array.new(1535, 0.0) }
  let(:source) do
    described_class.create!(
      account: account, agent: agent, source_type: 'txt', status: :ready,
      review_status: 'accepted', review_summary: 'Material bom e completo sobre o negócio.',
      review_label: 'otima', review_reason: 'Cobertura ampla.', quality_score: 9,
      confidence: 'alta', reviewed_at: 1.day.ago
    )
  end

  describe '#mark_failed! after a resync (G6)' do
    let!(:entry) do
      Autonomia::Agents::KnowledgeEntry.create!(
        account: account, agent: agent, source: source, chunk_index: 0, status: :ready,
        content: 'Horário de atendimento: segunda a sexta, das 9h às 18h.',
        embedding: embedding_vector
      )
    end

    def fail_resync_with_embedding_error
      token = source.begin_ingestion!
      ingestor = instance_double(Autonomia::Agents::Knowledge::Ingestor)
      allow(Autonomia::Agents::Knowledge::Ingestor).to receive(:new).and_return(ingestor)
      allow(ingestor).to receive(:perform)
        .and_raise(Autonomia::Agents::EmbeddingService::EmbeddingError, 'embedding_down')
      Autonomia::Agents::Knowledge::ProcessJob.perform_now(source.id, token)
    end

    it 'restores the previous accepted review when embedding fails during resync' do
      # Arrange
      expect(source).to be_accepted

      # Act
      fail_resync_with_embedding_error

      # Assert
      source.reload
      expect(source).to be_failed
      expect(source).to have_attributes(
        error: 'embedding_down', review_status: 'accepted', review_label: 'otima',
        review_summary: 'Material bom e completo sobre o negócio.',
        quality_score: 9, confidence: 'alta'
      )
      expect(source.reviewed_at).to be_present
    end

    it 'keeps the old chunks visible to the Retriever after a transient resync failure' do
      # Arrange
      fail_resync_with_embedding_error
      embedder = instance_double(Autonomia::Agents::EmbeddingService, embed: embedding_vector)
      allow(Autonomia::Agents::EmbeddingService).to receive(:new).and_return(embedder)

      # Act
      results = Autonomia::Agents::Retriever.new(agent: agent).retrieve('horário de atendimento')

      # Assert
      expect(results.map(&:id)).to include(entry.id)
    end

    it 'does not promote a never-reviewed source when its first ingestion fails' do
      # Arrange
      fresh = described_class.create!(account: account, agent: agent, source_type: 'txt')
      token = fresh.begin_ingestion!

      # Act
      fresh.mark_failed!(token, 'boom')

      # Assert
      fresh.reload
      expect(fresh).to be_failed
      expect(fresh.review_status).to eq('needs_review')
    end
  end
end
