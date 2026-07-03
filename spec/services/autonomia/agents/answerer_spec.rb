require 'rails_helper'

RSpec.describe Autonomia::Agents::Answerer do
  let(:account) { create(:account) }

  let(:model_reply) do
    {
      reply: 'Posso ajudar sim!', confidence: 0.9, should_handoff: false, handoff_reason: nil,
      used_snippet_ids: [], answered_from_knowledge: false
    }.to_json
  end

  before do
    resolver = instance_double(Crm::Ai::CredentialResolver, resolve: 'ai-credential')
    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(resolver)
    client = instance_double(Crm::Ai::ResponsesClient, create: { text: model_reply })
    allow(Crm::Ai::ResponsesClient).to receive(:new).and_return(client)
  end

  def create_agent(config)
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Bot', agent_type: 'custom', status: :active, enabled: true,
      instruction: 'Atenda o cliente.', config: config
    )
  end

  describe 'knowledge retrieval skip (C3)' do
    it 'never instantiates the Retriever for an agent with with_knowledge=false and still answers' do
      # Arrange
      agent = create_agent('with_knowledge' => false)
      expect(Autonomia::Agents::Retriever).not_to receive(:new)

      # Act
      result = described_class.new(agent: agent, query: 'oi', trust_instruction: true).answer

      # Assert
      expect(result.reply).to eq('Posso ajudar sim!')
    end

    it "treats the string 'false' (jsonb form) as knowledge disabled too" do
      # Arrange
      agent = create_agent('with_knowledge' => 'false')
      expect(Autonomia::Agents::Retriever).not_to receive(:new)

      # Act
      result = described_class.new(agent: agent, query: 'oi', trust_instruction: true).answer

      # Assert
      expect(result.reply).to eq('Posso ajudar sim!')
    end

    it 'runs retrieval when the with_knowledge key is absent (historic default = with knowledge)' do
      # Arrange
      agent = create_agent({})
      retriever = instance_double(Autonomia::Agents::Retriever, retrieve: [])
      expect(Autonomia::Agents::Retriever).to receive(:new).with(agent: agent).and_return(retriever)

      # Act
      result = described_class.new(agent: agent, query: 'oi', trust_instruction: true).answer

      # Assert
      expect(result.reply).to eq('Posso ajudar sim!')
    end

    it 'runs retrieval when with_knowledge is explicitly true' do
      # Arrange
      agent = create_agent('with_knowledge' => true)
      retriever = instance_double(Autonomia::Agents::Retriever, retrieve: [])
      expect(Autonomia::Agents::Retriever).to receive(:new).with(agent: agent).and_return(retriever)

      # Act
      described_class.new(agent: agent, query: 'oi', trust_instruction: true).answer
    end
  end
end
