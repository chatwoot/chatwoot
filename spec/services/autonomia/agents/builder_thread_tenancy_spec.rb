require 'rails_helper'

# T5 review — runtime FAIL-CLOSED do Construtor: uma BuildThread legada/corrompida apontando
# para agente de OUTRA conta (gravada antes da validação de tenancy, ou por write que burla o
# Rails) aborta a geração ANTES de qualquer chamada de IA/escrita — nunca lê a instruction
# alheia nem aplica config no agente de outra conta.
RSpec.describe Autonomia::Agents::Builder do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:foreign_agent) do
    Autonomia::Agents::Agent.create!(
      account: other_account, name: 'Alheio', agent_type: 'custom',
      instruction: 'Instrução secreta da outra conta.'
    )
  end
  let(:thread) { Autonomia::Agents::BuildThread.create!(account: account) }

  # Simula dado legado: update_column bypassa a validação de tenancy do BuildThread (D1).
  def link_foreign_agent!
    thread.update_column(:autonomia_agent_id, foreign_agent.id) # rubocop:disable Rails/SkipsModelValidations
    thread.reload
  end

  describe '#run! tenancy guard' do
    it 'aborts as failed without calling the model or touching the foreign agent' do
      # Arrange
      link_foreign_agent!
      token = thread.begin_build!
      allow(Crm::Ai::ResponsesClient).to receive(:new)
      allow(Rails.logger).to receive(:error)

      # Act
      described_class.new(account: account, build_thread: thread).run!(token)

      # Assert
      expect(Crm::Ai::ResponsesClient).not_to have_received(:new)
      expect(thread.reload).to be_failed
      expect(thread.state['error']).to eq('cross_account_agent')
      expect(foreign_agent.reload.instruction).to eq('Instrução secreta da outra conta.')
      expect(Rails.logger).to have_received(:error).with(/cross_account_agent thread=#{thread.id}/)
    end
  end

  describe 'SubmitJob integration' do
    it 'fails the thread without applying anything to the cross-account agent' do
      # Arrange
      link_foreign_agent!
      token = thread.begin_build!
      allow(Crm::Ai::ResponsesClient).to receive(:new)

      # Act
      Autonomia::Agents::Builder::SubmitJob.perform_now(thread.id, token)

      # Assert
      expect(Crm::Ai::ResponsesClient).not_to have_received(:new)
      expect(thread.reload).to be_failed
      expect(thread.state['error']).to eq('cross_account_agent')
      expect(foreign_agent.reload.name).to eq('Alheio')
    end
  end
end
