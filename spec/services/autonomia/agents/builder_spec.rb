require 'rails_helper'

RSpec.describe Autonomia::Agents::Builder do
  let(:account) { create(:account) }
  let(:thread) { Autonomia::Agents::BuildThread.create!(account: account) }
  let(:builder) { described_class.new(account: account, build_thread: thread) }

  def stub_model_output(parsed)
    fake_client = instance_double(Crm::Ai::ResponsesClient, create: { text: parsed.to_json })
    allow(builder).to receive(:client).and_return(fake_client)
  end

  describe 'assistant turn persistence (E1)' do
    let(:question) { 'Qual o nome do agente?' }

    before do
      thread.append_message!('user', 'Quero um agente de suporte')
      stub_model_output('needs_more_info' => true, 'next_question' => question)
    end

    it 'persists the interview question as an assistant message on the thread' do
      # Arrange
      token = thread.begin_build!

      # Act
      builder.run!(token)

      # Assert
      last = Array(thread.reload.messages).last
      expect(last['role']).to eq('assistant')
      expect(last['content']).to eq(question)
      expect(thread.state['next_question']).to eq(question)
      expect(thread).to be_ready
    end

    it 'does not duplicate the assistant turn when the same question repeats back to back' do
      # Arrange
      builder.run!(thread.begin_build!)

      # Act
      builder.run!(thread.begin_build!)

      # Assert
      assistant_turns = Array(thread.reload.messages).select { |m| m['role'] == 'assistant' }
      expect(assistant_turns.size).to eq(1)
    end

    it 'skips persistence when the generation was superseded (token lost)' do
      # Arrange
      stale_token = thread.begin_build!
      thread.begin_build! # nova geração assumiu; o token antigo perdeu

      # Act
      builder.run!(stale_token)

      # Assert
      expect(Array(thread.reload.messages).pluck('role')).not_to include('assistant')
    end
  end

  describe 'knowledge opt-out context (E5)' do
    let(:agent) do
      Autonomia::Agents::Agent.create!(
        account: account, name: 'Rascunho', agent_type: 'support', mode: :guided,
        status: :draft, enabled: false
      )
    end

    context 'when the thread was opened with with_knowledge=false' do
      before do
        thread.persist_start_options!(type: 'support', with_knowledge: false)
        thread.save!
        thread.update!(agent: agent)
      end

      it 'suppresses the ask-once material confirmation block and reports the choice as confirmed' do
        # Act
        context = builder.send(:materials_status_context)

        # Assert
        expect(context).not_to include('pergunte UMA vez')
        expect(context).to include('usuário declarou/confirmou não ter material: true')
      end

      it 'tells the model not to ask for the no-knowledge confirmation' do
        # Act
        context = builder.send(:knowledge_intent_context)

        # Assert
        expect(context).to include('NÃO pergunte se pode criar sem base de conhecimento')
        expect(context).to include('NÃO peça documentos')
      end
    end

    context 'when the thread keeps the default with-knowledge flow' do
      before do
        thread.persist_start_options!(type: 'support')
        thread.save!
        thread.update!(agent: agent)
      end

      it 'keeps the ask-once material confirmation block' do
        # Act
        context = builder.send(:materials_status_context)

        # Assert
        expect(context).to include('pergunte UMA vez')
        expect(context).to include('usuário declarou/confirmou não ter material: false')
      end

      it 'emits no knowledge opt-out block' do
        expect(builder.send(:knowledge_intent_context)).to eq('')
      end
    end
  end
end
