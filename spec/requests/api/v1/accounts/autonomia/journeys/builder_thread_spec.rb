require 'rails_helper'

# Jornada "caminhos tristes" do Construtor (BuildThreads): thread inexistente/de outra
# conta, thread cujo agente foi deletado e mensagem em branco. Documenta o comportamento
# ATUAL (dependent: :nullify mantém a thread viva sem agente).
RSpec.describe 'Autonomia journeys - builder threads', type: :request do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true' do
      example.run
    end
  end

  def create_agent
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Agente Construido', agent_type: 'support', mode: :guided,
      status: :draft, enabled: false, actuation: :external
    )
  end

  def post_message(thread_id, message: 'Quero um agente de suporte')
    post "/api/v1/accounts/#{account.id}/autonomia/build_threads/#{thread_id}/messages",
         params: { message: message },
         headers: administrator.create_new_auth_token, as: :json
  end

  it 'returns 404 when posting a message to a nonexistent thread' do
    # Act
    post_message(999_999)

    # Assert
    expect(response).to have_http_status(:not_found)
  end

  it 'returns 404 when posting a message to a thread of another account' do
    # Arrange — thread pertence à conta B; o escopo build_threads_scope é por conta.
    other_account = create(:account, internal_attributes: { 'autonomia_agents_enabled' => true })
    foreign_thread = Autonomia::Agents::BuildThread.create!(account: other_account)

    # Act
    post_message(foreign_thread.id)

    # Assert — IDOR bloqueado: nem leitura nem escrita cross-account.
    expect(response).to have_http_status(:not_found)
    expect(foreign_thread.reload.messages).to be_blank
  end

  it 'keeps the thread alive (agent nulled) after the agent is deleted and still accepts messages' do
    # Arrange — thread ligada a um agente que é deletado em seguida.
    agent = create_agent
    thread = Autonomia::Agents::BuildThread.create!(account: account, agent: agent)
    agent.destroy!

    # Act — comportamento ATUAL: dependent: :nullify preserva a thread; a conversa do
    # Construtor continua e o Builder criará um rascunho novo se fechar de novo.
    post_message(thread.id, message: 'Continuar mesmo sem o agente')

    # Assert
    expect(response).to have_http_status(:accepted)
    thread.reload
    expect(thread.autonomia_agent_id).to be_nil
    expect(thread.messages.last['content']).to eq('Continuar mesmo sem o agente')
    expect(thread.status).to eq('processing')
  end

  it 'rejects a blank continuation message with 422' do
    # Arrange
    thread = Autonomia::Agents::BuildThread.create!(account: account, agent: create_agent)

    # Act
    post_message(thread.id, message: '')

    # Assert — o guard de mensagem em branco vale só na continuação (não na abertura).
    expect(response).to have_http_status(:unprocessable_entity)
    expect(thread.reload.messages).to be_blank
  end
end
