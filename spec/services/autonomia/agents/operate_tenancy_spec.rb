require 'rails_helper'

# T5 review — leitura FAIL-CLOSED do vínculo agente↔inbox: um AgentInbox legado/corrompido
# cross-tenant (gravado antes da validação de tenancy, ou por write que burla o Rails) nunca
# pode fazer a conversa da conta A responder com agente/KB da conta B.
RSpec.describe Autonomia::Agents::Operate do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent_bot) { AgentBot.create!(account: account, name: 'Espelho') }

  def create_agent(owner)
    Autonomia::Agents::Agent.create!(
      account: owner, name: 'Agente', agent_type: 'custom', status: :active, enabled: true
    )
  end

  # Simula registro legado: bypassa a validação de tenancy do AgentInbox (D1).
  def create_legacy_link(agent, link_account: account, bot: agent_bot)
    link = Autonomia::Agents::AgentInbox.new(account: link_account, inbox: inbox, agent: agent, agent_bot: bot)
    link.save!(validate: false)
    link
  end

  before { allow(Autonomia::Agents::Config).to receive(:enabled?).and_return(true) }

  describe '.eligible_agent_inbox tenancy guard' do
    it 'returns the link when the agent belongs to the conversation account' do
      # Arrange
      link = create_legacy_link(create_agent(account))

      # Act / Assert
      expect(described_class.eligible_agent_inbox(conversation)).to eq(link)
    end

    it 'behaves as "no agent" when the linked agent belongs to another account' do
      # Arrange
      create_legacy_link(create_agent(other_account))

      # Act / Assert
      expect(described_class.eligible_agent_inbox(conversation)).to be_nil
    end

    it 'ignores a link row scoped to another account' do
      # Arrange
      foreign_bot = AgentBot.create!(account: other_account, name: 'Bot alheio')
      create_legacy_link(create_agent(other_account), link_account: other_account, bot: foreign_bot)

      # Act / Assert
      expect(described_class.eligible_agent_inbox(conversation)).to be_nil
    end
  end
end
