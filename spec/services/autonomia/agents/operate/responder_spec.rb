require 'rails_helper'

RSpec.describe Autonomia::Agents::Operate::Responder do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: nil) }
  let(:agent_bot) { create(:agent_bot, account: account) }

  let(:agent) do
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Bot', agent_type: 'custom', status: :active, enabled: true,
      instruction: 'Atenda o cliente.'
    )
  end

  let(:agent_inbox) do
    Autonomia::Agents::AgentInbox.create!(agent: agent, inbox: inbox, account: account, agent_bot: agent_bot)
  end

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true' do
      example.run
    end
  end

  describe 'pre-answer eligibility recheck (C4)' do
    it 'never calls the LLM when the conversation became ineligible before answering' do
      # Arrange: humano assumiu a conversa entre o debounce e o perform
      conversation.update!(assignee: create(:user, account: account, role: :agent))
      expect(Autonomia::Agents::Answerer).not_to receive(:new)

      # Act
      result = described_class.new(conversation: conversation, agent_inbox: agent_inbox).perform

      # Assert
      expect(result.status).to eq(:silenced)
    end

    it 'still calls the answerer when the conversation remains eligible' do
      # Arrange: conversa sem responsável + vínculo ativo -> elegível; IA devolve silêncio (nada a postar)
      silent = Autonomia::Agents::AnswerResult.new(
        reply: nil, confidence: 0.0, handoff: { should: false, reason: nil },
        used_knowledge: [], answered_from_knowledge: false, raw_reply: nil, error: 'ai_unavailable'
      )
      answerer = instance_double(Autonomia::Agents::Answerer, answer: silent)
      expect(Autonomia::Agents::Answerer).to receive(:new).and_return(answerer)

      # Act
      result = described_class.new(conversation: conversation, agent_inbox: agent_inbox).perform

      # Assert
      expect(result.status).to eq(:silenced)
    end
  end
end
