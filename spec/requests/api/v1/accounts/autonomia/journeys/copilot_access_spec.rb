require 'rails_helper'

# Jornada "caminhos tristes" do widget "Copiloto Autonom.ia" (endpoint agent-facing,
# não admin): flags desligadas, tenancy do seletor e do chat, conversa inexistente/de
# outra conta e o fluxo do chat com agente sem base (with_knowledge=false).
# O caso interno draft-fora/ativo-dentro já é coberto por internal_agent_activation_spec.
RSpec.describe 'Autonomia journeys - conversation copilot access', type: :request do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:conversation) { create(:conversation, account: account) }

  let(:other_account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true', CRM_KANBAN_ENABLED: 'true', CRM_COPILOT_ENABLED: 'true' do
      example.run
    end
  end

  def create_copilot_agent(owner_account, attrs = {})
    Autonomia::Agents::Agent.create!(
      { account: owner_account, name: "Copiloto #{SecureRandom.hex(3)}", agent_type: 'custom', mode: :guided,
        status: :active, enabled: true, actuation: :internal,
        instruction: 'Ajude a equipe.' }.merge(attrs)
    )
  end

  def list_agents(conversation_id: conversation.display_id)
    get "/api/v1/accounts/#{account.id}/autonomia/conversations/#{conversation_id}/copilot/agents",
        headers: administrator.create_new_auth_token, as: :json
  end

  describe 'GET copilot/agents (selector)' do
    it 'lists an active both-actuation agent in the copilot selector' do
      # Arrange — variação `both`: além de conectar canal, entra no seletor do copiloto.
      both_agent = create_copilot_agent(account, actuation: :both)

      # Act
      list_agents

      # Assert — listado sem vazar instruction/scaffold/config.
      expect(response).to have_http_status(:success)
      listed = response.parsed_body['agents']
      expect(listed.pluck('id')).to include(both_agent.id)
      entry = listed.find { |a| a['id'] == both_agent.id }
      expect(entry['actuation']).to eq('both')
      expect(entry.keys).to match_array(%w[id name actuation description])
    end

    it 'never lists agents that belong to another account' do
      # Arrange — agente ativo/interno da conta B; seletor consultado na conta A.
      foreign_agent = create_copilot_agent(other_account)
      create_copilot_agent(account) # controle: o da própria conta aparece

      # Act
      list_agents

      # Assert — isolamento de conta no seletor.
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['agents'].pluck('id')).not_to include(foreign_agent.id)
    end

    it 'returns 404 when the copilot flag is off' do
      # Arrange / Act — só o CRM_COPILOT_ENABLED desligado já fecha o endpoint.
      with_modified_env CRM_COPILOT_ENABLED: 'false' do
        list_agents
      end

      # Assert
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when the kanban flag is off' do
      # Arrange / Act — copiloto depende do gate do kanban ("kanban on => copilot").
      with_modified_env CRM_KANBAN_ENABLED: 'false' do
        list_agents
      end

      # Assert
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST copilot/chat' do
    def chat(conversation_id:, agent_id:, message: 'Resuma a conversa')
      post "/api/v1/accounts/#{account.id}/autonomia/conversations/#{conversation_id}/copilot/chat",
           params: { agent_id: agent_id, message: message },
           headers: administrator.create_new_auth_token, as: :json
    end

    it 'returns 404 for a nonexistent conversation' do
      # Arrange
      agent = create_copilot_agent(account)

      # Act
      chat(conversation_id: 999_999, agent_id: agent.id)

      # Assert
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for a display_id that only exists in another account' do
      # Arrange — conversa criada SÓ na conta B; a rota usa a conta A.
      foreign_conversation = create(:conversation, account: other_account)
      agent = create_copilot_agent(account)

      # Act
      chat(conversation_id: foreign_conversation.display_id, agent_id: agent.id)

      # Assert — display_id é por conta: na conta A esse id não existe.
      expect(response).to have_http_status(:not_found)
    end

    it 'returns available:false when the selected agent belongs to another account' do
      # Arrange — agente válido, mas da conta B (resolve_agent escopa pela conta da conversa).
      foreign_agent = create_copilot_agent(other_account)

      # Act — CRM_AI_ENABLED ligado para passar do gate de IA e exercitar o escopo do agente.
      with_modified_env CRM_AI_ENABLED: 'true' do
        chat(conversation_id: conversation.display_id, agent_id: foreign_agent.id)
      end

      # Assert — best-effort: nunca 500/404 aqui; o chat responde indisponível.
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['available']).to be(false)
      expect(response.parsed_body['text']).to be_nil
    end

    it 'flows normally for an agent declared without a knowledge base (with_knowledge=false)' do
      # Arrange — agente interno sem base declarada; a resposta vem só da instrução
      # (grounded=false). O motor de IA é dublê: o spec cobre o encanamento do chat.
      agent = create_copilot_agent(account, config: { 'with_knowledge' => false })
      result = Autonomia::Agents::AnswerResult.new(
        reply: 'Resumo: cliente pediu troca.', confidence: 0.9,
        handoff: { should: false, reason: nil },
        answered_from_knowledge: false, raw_reply: 'Resumo: cliente pediu troca.'
      )
      copilot = instance_double(Autonomia::Agents::Copilot, suggest: result)
      allow(Autonomia::Agents::Copilot).to receive(:new).and_return(copilot)

      # Act
      with_modified_env CRM_AI_ENABLED: 'true' do
        chat(conversation_id: conversation.display_id, agent_id: agent.id)
      end

      # Assert — disponível, com sugestão de resposta, e SEM grounding (sem base).
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body['available']).to be(true)
      expect(body['text']).to eq('Resumo: cliente pediu troca.')
      expect(body['grounded']).to be(false)
      expect(body['reply_suggestion']).to be(true)
    end
  end
end
