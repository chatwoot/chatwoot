require 'rails_helper'

# Jornada "caminhos tristes" do runtime externo (Operar): o predicado canônico
# Operate.eligible_agent_inbox decide se o agente responde uma conversa. Aqui ficam os
# gates que fazem o agente NÃO responder (pausado, desligado, interno, humano no
# comando, flag da conta off) — com um controle feliz para ancorar o contrato.
# O arquivo vive em services/autonomia/journeys (suíte de jornadas), não no espelho
# exato do path da classe — por isso o disable pontual do SpecFilePathFormat.
RSpec.describe Autonomia::Agents::Operate do # rubocop:disable RSpec/SpecFilePathFormat
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent) do
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Operadora', agent_type: 'support', mode: :guided,
      status: :active, enabled: true, actuation: :external, instruction: 'Atenda bem.'
    )
  end
  let!(:agent_inbox) do
    result = Autonomia::Agents::Operate::InboxConnector.new(agent: agent, inbox: conversation.inbox)
                                                       .perform(connect: true)
    raise "setup failed: #{result.error}" unless result.success?

    result.agent_inbox
  end

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true' do
      example.run
    end
  end

  def eligible(conv)
    Autonomia::Agents::Operate.eligible_agent_inbox(conv)
  end

  describe '.eligible_agent_inbox' do
    it 'returns the agent inbox for an active enabled external agent (happy control)' do
      # Act / Assert — âncora do contrato: tudo ligado -> elegível.
      expect(eligible(conversation)).to eq(agent_inbox)
    end

    it 'skips the conversation when the agent is paused' do
      # Arrange — pausa NÃO desconecta o canal, mas o Operate deixa de agir.
      agent.update!(status: :paused)

      # Act / Assert
      expect(eligible(conversation)).to be_nil
      expect(agent.agent_inboxes.count).to eq(1) # vínculo preservado
    end

    it 'skips the conversation when the agent is disabled' do
      # Arrange
      agent.update!(enabled: false)

      # Act / Assert
      expect(eligible(conversation)).to be_nil
    end

    it 'skips the conversation when the agent was flipped to internal' do
      # Arrange — defesa em profundidade: mesmo se um vínculo sobreviver (ex.: corrida com o
      # reject do update), o runtime nunca deixa um interno falar com cliente.
      agent.update!(actuation: :internal)

      # Act / Assert
      expect(eligible(conversation)).to be_nil
    end

    it 'skips the conversation once a human takes over (assignee present)' do
      # Arrange
      human = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: conversation.inbox, user: human)
      conversation.update!(assignee: human)

      # Act / Assert
      expect(eligible(conversation)).to be_nil
    end

    it 'skips the conversation when the account feature flag is turned off' do
      # Arrange — kill-switch por conta: desligar a marca interna cala o agente na hora.
      account.update!(internal_attributes: { 'autonomia_agents_enabled' => false })

      # Act / Assert
      expect(eligible(conversation.reload)).to be_nil
    end

    it 'keeps a both-actuation agent eligible for external conversations' do
      # Arrange — `both` atende cliente E serve de copiloto.
      agent.update!(actuation: :both)

      # Act / Assert
      expect(eligible(conversation)).to eq(agent_inbox)
    end
  end
end
