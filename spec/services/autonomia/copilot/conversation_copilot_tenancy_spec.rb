require 'rails_helper'

# T5 review — o draft do copiloto de conversa só pode ser fundamentado (grounded) por um agente
# da MESMA conta da conversa. Um AgentInbox legado cross-tenant cai no rascunho genérico,
# nunca na KB de outra conta.
RSpec.describe Autonomia::Copilot::ConversationCopilot do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent_bot) { AgentBot.create!(account: account, name: 'Espelho') }
  let(:client) { instance_double(Crm::Ai::ResponsesClient, create: { text: 'rascunho genérico' }) }

  def create_agent(owner)
    Autonomia::Agents::Agent.create!(
      account: owner, name: 'Agente', agent_type: 'custom', status: :active, enabled: true,
      instruction: 'Responda com base na KB.'
    )
  end

  # Simula registro legado: bypassa a validação de tenancy do AgentInbox (D1).
  def create_legacy_link(agent)
    link = Autonomia::Agents::AgentInbox.new(account: account, inbox: inbox, agent: agent, agent_bot: agent_bot)
    link.save!(validate: false)
    link
  end

  before do
    create(:message, conversation: conversation, account: account, inbox: inbox,
                     message_type: :incoming, content: 'Preciso de ajuda com meu pedido')
    allow(Crm::Ai::Config).to receive(:enabled?).and_return(true)
    allow(Crm::Ai::CredentialResolver).to receive(:new)
      .and_return(instance_double(Crm::Ai::CredentialResolver, resolve: 'credential'))
    allow(Crm::Ai::ResponsesClient).to receive(:new).and_return(client)
  end

  describe 'draft task tenancy' do
    it 'grounds the draft on a same-account linked agent' do
      # Arrange
      agent = create_agent(account)
      create_legacy_link(agent)
      answer = instance_double(Autonomia::Agents::AnswerResult, reply: 'resposta com KB', raw_reply: 'resposta com KB')
      allow(Autonomia::Agents::Copilot).to receive(:new)
        .and_return(instance_double(Autonomia::Agents::Copilot, suggest: answer))

      # Act
      result = described_class.new(conversation: conversation, task: 'draft').perform

      # Assert
      expect(Autonomia::Agents::Copilot).to have_received(:new).with(hash_including(agent: agent))
      expect(result.grounded).to be true
    end

    it 'never grounds on a cross-account agent from a legacy link' do
      # Arrange
      create_legacy_link(create_agent(other_account))
      allow(Autonomia::Agents::Copilot).to receive(:new)

      # Act
      result = described_class.new(conversation: conversation, task: 'draft').perform

      # Assert
      expect(Autonomia::Agents::Copilot).not_to have_received(:new)
      expect(result.grounded).to be false
      expect(result.available).to be true
    end
  end
end
