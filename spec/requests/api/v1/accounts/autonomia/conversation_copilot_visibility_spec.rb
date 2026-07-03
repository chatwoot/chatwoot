require 'rails_helper'

# D2 — o copiloto de conversa deve respeitar a visibilidade CRM `assigned_only`:
# um atendente membro da caixa mas que não é responsável/participante não pode
# mandar o transcript da conversa para o LLM.
RSpec.describe 'Conversation copilot CRM visibility', type: :request do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent_user) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:inbox_member, inbox: inbox, user: agent_user)
    copilot_result = Autonomia::Copilot::ConversationCopilot::Result.new(text: 'ok', grounded: true, available: true)
    allow(Autonomia::Copilot::ConversationCopilot).to receive(:new)
      .and_return(instance_double(Autonomia::Copilot::ConversationCopilot, perform: copilot_result))
  end

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true', CRM_KANBAN_ENABLED: 'true', CRM_COPILOT_ENABLED: 'true' do
      example.run
    end
  end

  def request_copilot(user)
    post "/api/v1/accounts/#{account.id}/autonomia/conversations/#{conversation.display_id}/copilot",
         params: { task: 'summarize' },
         headers: user.create_new_auth_token,
         as: :json
  end

  context 'when the inbox has no assigned_only restriction' do
    it 'allows an inbox member to use the copilot' do
      # Arrange (default inbox, no CRM setting)

      # Act
      request_copilot(agent_user)

      # Assert
      expect(response).to have_http_status(:success)
    end
  end

  context 'when the inbox is assigned_only' do
    before { Crm::InboxSetting.create!(account: account, inbox: inbox, visibility_mode: :assigned_only) }

    it 'blocks an inbox member who is not assignee nor participant' do
      # Arrange (conversation unassigned)

      # Act
      request_copilot(agent_user)

      # Assert
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows the assignee' do
      # Arrange
      conversation.update!(assignee: agent_user)

      # Act
      request_copilot(agent_user)

      # Assert
      expect(response).to have_http_status(:success)
    end

    it 'allows an administrator' do
      # Arrange
      administrator = create(:user, account: account, role: :administrator)

      # Act
      request_copilot(administrator)

      # Assert
      expect(response).to have_http_status(:success)
    end
  end
end
