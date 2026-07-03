require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::DocumentClassifier do
  let(:account) { create(:account) }
  let(:agent) do
    Autonomia::Agents::Agent.create!(account: account, name: 'Agente Teste', agent_type: 'support')
  end
  let(:source) do
    Autonomia::Agents::Source.create!(account: account, agent: agent, source_type: 'pdf', status: :processing)
  end
  let(:resolver) { instance_double(Crm::Ai::CredentialResolver, resolve: 'cred') }
  let(:client) { instance_double(Crm::Ai::ResponsesClient) }

  before do
    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(resolver)
    allow(Crm::Ai::ResponsesClient).to receive(:new).and_return(client)
  end

  describe '#classify' do
    it 'makes ONE LLM call and maps the schema into topics/entities/doc_style' do
      # Arrange
      payload = {
        text: { topics: %w[Reembolso Trocas], entities: ['Plano Plus'], doc_style: 'formal' }.to_json
      }
      expect(client).to receive(:create).once.and_return(payload)

      # Act
      result = described_class.new(source: source, text: 'Politica de reembolso e trocas.').classify

      # Assert
      expect(result).to eq(topics: %w[Reembolso Trocas], entities: ['Plano Plus'], doc_style: 'formal')
    end

    it 'caps topics/entities and drops case/whitespace duplicates' do
      # Arrange — 9 topics (cap 8) com duplicata por caixa; doc_style invalido vira nil.
      topics = %w[Reembolso reembolso Trocas Prazos Frete Pagamento Garantia Suporte Extra]
      payload = { text: { topics: topics, entities: [], doc_style: 'invalido' }.to_json }
      allow(client).to receive(:create).and_return(payload)

      # Act
      result = described_class.new(source: source, text: 'conteudo').classify

      # Assert
      expect(result[:topics].size).to eq(described_class::TOPICS_CAP)
      expect(result[:topics].map(&:downcase)).to eq(result[:topics].map(&:downcase).uniq)
      expect(result[:doc_style]).to be_nil
    end

    it 'degrades to EMPTY on a ResponsesClient error (never raises)' do
      # Arrange
      allow(client).to receive(:create).and_raise(Crm::Ai::ResponsesClient::Error, 'boom')

      # Act
      result = described_class.new(source: source, text: 'conteudo').classify

      # Assert
      expect(result).to eq(topics: [], entities: [], doc_style: nil)
    end

    it 'degrades to EMPTY on invalid JSON' do
      # Arrange
      allow(client).to receive(:create).and_return(text: 'not-json{')

      # Act
      result = described_class.new(source: source, text: 'conteudo').classify

      # Assert
      expect(result).to eq(Autonomia::Agents::Knowledge::DocumentClassifier::EMPTY)
    end

    it 'returns EMPTY without any LLM call when the text is blank' do
      # Arrange
      expect(Crm::Ai::ResponsesClient).not_to receive(:new)

      # Act
      result = described_class.new(source: source, text: '   ').classify

      # Assert
      expect(result).to eq(topics: [], entities: [], doc_style: nil)
    end

    it 'degrades to EMPTY when no AI credential is configured' do
      # Arrange
      allow(resolver).to receive(:resolve).and_return(nil)

      # Act
      result = described_class.new(source: source, text: 'conteudo').classify

      # Assert
      expect(result).to eq(topics: [], entities: [], doc_style: nil)
    end
  end
end
