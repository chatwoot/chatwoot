require 'rails_helper'

# Fluxo de publicação do agente INTERNO (copiloto da equipe): sem canal para
# conectar, a ativação é direta (status active + enabled) e é o que o faz
# aparecer no seletor do widget "Copiloto Autonom.ia" da conversa.
RSpec.describe 'Internal agent activation', type: :request do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent_user) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  let!(:internal_agent) do
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Copiloto Interno', agent_type: 'custom', mode: :guided,
      status: :draft, enabled: false, actuation: :internal,
      instruction: 'Ajude a equipe a resumir conversas e aplicar as condições gerais.'
    )
  end

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true', CRM_KANBAN_ENABLED: 'true', CRM_COPILOT_ENABLED: 'true' do
      example.run
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/autonomia/agents/:id' do
    it 'activates an internal draft agent without any connected channel' do
      patch "/api/v1/accounts/#{account.id}/autonomia/agents/#{internal_agent.id}",
            params: { agent: { status: 'active', enabled: true } },
            headers: administrator.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(internal_agent.reload).to have_attributes(status: 'active', enabled: true)
    end

    it 'stays admin-only' do
      patch "/api/v1/accounts/#{account.id}/autonomia/agents/#{internal_agent.id}",
            params: { agent: { status: 'active', enabled: true } },
            headers: agent_user.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(internal_agent.reload.status).to eq('draft')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/autonomia/conversations/:conversation_id/copilot/agents' do
    def list_copilot_agents(user)
      get "/api/v1/accounts/#{account.id}/autonomia/conversations/#{conversation.display_id}/copilot/agents",
          headers: user.create_new_auth_token,
          as: :json
      response.parsed_body['agents'] || []
    end

    it 'omits the internal agent while it is a draft and lists it once activated' do
      expect(list_copilot_agents(administrator).pluck('id')).not_to include(internal_agent.id)

      internal_agent.update!(status: :active, enabled: true)

      listed = list_copilot_agents(administrator)
      expect(listed.pluck('id')).to include(internal_agent.id)
      expect(listed.find { |a| a['id'] == internal_agent.id }).not_to have_key('instruction')
    end

    it 'keeps system agents (Guia) out of the selector' do
      Autonomia::Agents::Agent.create!(
        account: account, name: 'Guia', agent_type: 'custom', mode: :manual,
        status: :active, enabled: true, actuation: :internal,
        instruction: 'guia', config: { 'system_key' => 'platform_guide' }
      )

      expect(list_copilot_agents(administrator).pluck('name')).not_to include('Guia')
    end
  end
end
