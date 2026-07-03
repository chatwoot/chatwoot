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
end
