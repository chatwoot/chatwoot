require 'rails_helper'

# Jornada "caminhos tristes" da conexão de canal (agente ↔ inbox): coexistência de
# bots (1 bot por inbox), agente interno bloqueado, agente não-ativo bloqueado e a
# variação `both` (única atuação que conecta canal E entra no copiloto).
RSpec.describe 'Autonomia journeys - channel connection', type: :request do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true' do
      example.run
    end
  end

  def create_agent(attrs = {})
    Autonomia::Agents::Agent.create!(
      { account: account, name: "Agente #{SecureRandom.hex(3)}", agent_type: 'support', mode: :guided,
        status: :active, enabled: true, actuation: :external, instruction: 'Atenda bem.' }.merge(attrs)
    )
  end

  def connect(agent, target_inbox)
    post "/api/v1/accounts/#{account.id}/autonomia/agents/#{agent.id}/channels",
         params: { inbox_id: target_inbox.id },
         headers: administrator.create_new_auth_token, as: :json
  end

  it 'rejects connecting an inbox already taken by another agent' do
    # Arrange — o primeiro agente ocupa o inbox.
    first_agent = create_agent
    second_agent = create_agent
    connect(first_agent, inbox)
    expect(response).to have_http_status(:created)

    # Act — o segundo tenta o MESMO inbox.
    connect(second_agent, inbox)

    # Assert — UNIQUE de 1 bot por inbox: 422 e nenhum vínculo novo criado.
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to be_present
    expect(Autonomia::Agents::AgentInbox.where(inbox_id: inbox.id).count).to eq(1)
    expect(Autonomia::Agents::AgentInbox.find_by(inbox_id: inbox.id).autonomia_agent_id).to eq(first_agent.id)
  end

  it 'rejects connecting a channel to an internal agent' do
    # Arrange — interno (copiloto da equipe) nunca atende cliente.
    internal_agent = create_agent(actuation: :internal)

    # Act
    connect(internal_agent, inbox)

    # Assert — bloqueio no backend (InboxConnector), sem AgentBot/AgentBotInbox criados.
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Autonomia::Agents::AgentInbox.where(autonomia_agent_id: internal_agent.id)).to be_empty
    expect(AgentBotInbox.where(inbox_id: inbox.id)).to be_empty
  end

  it 'rejects connecting a channel to a draft (not active) agent' do
    # Arrange
    draft_agent = create_agent(status: :draft, enabled: false)

    # Act
    connect(draft_agent, inbox)

    # Assert — só agente ativo+habilitado conecta canal.
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Autonomia::Agents::AgentInbox.where(autonomia_agent_id: draft_agent.id)).to be_empty
  end

  it 'rejects connecting when the inbox already has a real webhook bot (Gabriela)' do
    # Arrange — bot webhook REAL (outgoing_url presente) ocupando o inbox.
    webhook_bot = AgentBot.create!(account: account, name: 'Gabriela', outgoing_url: 'https://example.com/hook')
    AgentBotInbox.create!(inbox: inbox, agent_bot: webhook_bot, account: account)
    agent = create_agent

    # Act
    connect(agent, inbox)

    # Assert — coexistência proibida: webhook OU agente nativo, nunca os dois.
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Autonomia::Agents::AgentInbox.where(inbox_id: inbox.id)).to be_empty
  end

  it 'allows a both-actuation agent to connect a channel' do
    # Arrange — `both` atua externo E interno; canal é permitido.
    both_agent = create_agent(actuation: :both)

    # Act
    connect(both_agent, inbox)

    # Assert — vínculo + espelho criados normalmente.
    expect(response).to have_http_status(:created)
    agent_inbox = Autonomia::Agents::AgentInbox.find_by(inbox_id: inbox.id)
    expect(agent_inbox.autonomia_agent_id).to eq(both_agent.id)
    expect(AgentBot.find(agent_inbox.agent_bot_id).outgoing_url).to be_nil
  end
end
