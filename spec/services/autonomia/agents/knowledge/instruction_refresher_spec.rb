require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::InstructionRefresher do
  let(:account) { create(:account) }
  let(:original_instruction) { 'Instrução original do agente fechada pelo Construtor.' }
  let(:agent) do
    Autonomia::Agents::Agent.create!(
      account: account, name: 'Agente Teste', agent_type: 'support',
      mode: mode, instruction: original_instruction
    )
  end
  let(:client) { instance_double(Crm::Ai::ResponsesClient) }
  let(:resolver) { instance_double(Crm::Ai::CredentialResolver, resolve: 'test-credential') }

  before do
    allow(Crm::Ai::ResponsesClient).to receive(:new).and_return(client)
    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(resolver)
    allow(Rails.logger).to receive(:info).and_call_original
  end

  describe '.call' do
    context 'when the agent is in manual mode' do
      let(:mode) { :manual }

      it 'keeps the hand-written instruction intact and never calls the LLM' do
        # Arrange
        expect(Crm::Ai::ResponsesClient).not_to receive(:new)

        # Act
        result = described_class.call(agent, reason: :kb_changed)

        # Assert
        expect(result).to be_nil
        expect(agent.reload.instruction).to eq(original_instruction)
      end

      it 'emits skipped_manual telemetry' do
        # Arrange / Act
        described_class.call(agent, reason: :kb_changed)

        # Assert
        expect(Rails.logger).to have_received(:info).with(/status=skipped_manual/)
      end
    end

    context 'when the agent is in guided mode' do
      let(:mode) { :guided }

      it 'refreshes the instruction with the LLM result' do
        # Arrange
        allow(client).to receive(:create)
          .and_return({ text: { 'instruction' => 'Instrução atualizada pela IA.' }.to_json })

        # Act
        result = described_class.call(agent, reason: :kb_changed)

        # Assert
        expect(result).to eq('Instrução atualizada pela IA.')
        expect(agent.reload.instruction).to eq('Instrução atualizada pela IA.')
        expect(Rails.logger).to have_received(:info).with(/status=refreshed/)
      end

      it 'discards the LLM result when the agent switches to manual mode during generation' do
        # Arrange — simula o usuário virando o agente para modo MANUAL enquanto o modelo redige:
        # a instrução NÃO muda (o guard de before_instruction não pega), só o mode. G1: a instrução
        # agora é do usuário e o refresh automático não pode reescrevê-la.
        allow(client).to receive(:create) do
          Autonomia::Agents::Agent.find(agent.id).update!(mode: :manual)
          { text: { 'instruction' => 'Instrução atualizada pela IA.' }.to_json }
        end

        # Act
        result = described_class.call(agent, reason: :kb_changed)

        # Assert
        expect(result).to be_nil
        expect(agent.reload.instruction).to eq(original_instruction)
        expect(Rails.logger).to have_received(:info).with(/status=skipped_manual/)
      end

      it 'discards the LLM result when the user edits the instruction concurrently' do
        # Arrange — simula o PanelTune/ajuste manual gravando enquanto o modelo redige: o token de
        # coalescência NÃO muda (não houve mudança de base), só a instrução no banco.
        user_edit = 'Instrução editada pelo usuário no painel durante a geração.'
        allow(client).to receive(:create) do
          Autonomia::Agents::Agent.find(agent.id).update!(instruction: user_edit)
          { text: { 'instruction' => 'Instrução atualizada pela IA.' }.to_json }
        end

        # Act
        result = described_class.call(agent, reason: :kb_changed)

        # Assert
        expect(result).to be_nil
        expect(agent.reload.instruction).to eq(user_edit)
        expect(Rails.logger).to have_received(:info).with(/status=superseded/)
      end
    end
  end
end
