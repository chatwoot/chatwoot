require 'rails_helper'

RSpec.describe Synapseos::LeadLifecycle do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:lead) { create(:synapseos_lead, account: account, conversation: conversation) }

  # Cria os stages que a máquina usa por slug (template audi_sdr).
  let!(:stage_quer) do
    create(:synapseos_pipeline_stage, account: account, slug: 'aguardando_atendimento_humano',
                                      name: 'Aguardando atendimento humano', stage_type: 'working')
  end
  let!(:stage_futuro) do
    create(:synapseos_pipeline_stage, account: account, slug: 'futuro', name: 'Futuro', stage_type: 'open')
  end
  let!(:stage_encerrado) do
    create(:synapseos_pipeline_stage, account: account, slug: 'encerrado', name: 'Encerrado', stage_type: 'lost')
  end

  describe '.transition' do
    context 'with :quer' do
      it 'moves to quer, non-terminal, sets SLA next_action_at and qualifies' do
        freeze_time do
          described_class.transition(lead: lead, signal: :quer, modelo_interesse: 'A4')
          lead.reload
          expect(lead.estado).to eq('quer')
          expect(lead.pipeline_stage_id).to eq(stage_quer.id)
          expect(lead.status).to eq('qualified')
          expect(lead.next_action_at).to eq(Time.current + described_class::QUER_SLA)
          expect(lead.modelo_interesse).to eq('A4')
          expect(lead.terminal?).to be(false)
        end
      end
    end

    context 'with :quer_depois' do
      it 'uses the horizonte_compra bucket for retomada_at' do
        freeze_time do
          described_class.transition(lead: lead, signal: :quer_depois, horizonte_compra: '3-6m')
          lead.reload
          expect(lead.estado).to eq('quer_depois')
          expect(lead.pipeline_stage_id).to eq(stage_futuro.id)
          expect(lead.retomada_at).to eq(Time.current + 3.months)
          expect(lead.next_action_at).to eq(lead.retomada_at)
        end
      end

      it 'falls back to now when horizonte is imediato/unknown' do
        freeze_time do
          described_class.transition(lead: lead, signal: :quer_depois, horizonte_compra: 'imediato')
          lead.reload
          expect(lead.retomada_at).to eq(Time.current)
          expect(lead.next_action_at).to eq(Time.current)
        end
      end
    end

    context 'with :nao_quer' do
      it 'requires motivo' do
        expect do
          described_class.transition(lead: lead, signal: :nao_quer)
        end.to raise_error(described_class::MotivoRequired)
      end

      it 'is terminal, disqualifies, clears next_action_at and auto-resolves the conversation' do
        described_class.transition(lead: lead, signal: :nao_quer, motivo: 'sem interesse')
        lead.reload
        expect(lead.estado).to eq('nao_quer')
        expect(lead.motivo).to eq('sem interesse')
        expect(lead.status).to eq('disqualified')
        expect(lead.next_action_at).to be_nil
        expect(lead.pipeline_stage_id).to eq(stage_encerrado.id)
        expect(lead.conversation.reload.status).to eq('resolved')
      end
    end

    context 'with :sem_resposta_toque' do
      it 'increments cadence_touch and schedules next touch (non-terminal)' do
        freeze_time do
          described_class.transition(lead: lead, signal: :sem_resposta_toque)
          lead.reload
          expect(lead.estado).to eq('sem_resposta')
          expect(lead.cadence_touch).to eq(1)
          expect(lead.next_action_at).to eq(Time.current + 1.hour)
        end
      end

      it 'honors an explicit cadence_touch override' do
        described_class.transition(lead: lead, signal: :sem_resposta_toque, cadence_touch: 4)
        lead.reload
        expect(lead.cadence_touch).to eq(4)
      end
    end

    context 'with :sem_resposta_esgotou' do
      # Silêncio NÃO é intenção declarada: a coluna Futuro é de quem RESPONDEU
      # dizendo que troca mais pra frente. Quem não respondeu a nenhum toque vai
      # pra Encerrado (definição do próprio pipeline: "sem resposta após
      # cadência completa"), mas segue com retomada em +90d.
      it 'goes to Encerrado as sem_resposta, never to Futuro' do
        freeze_time do
          described_class.transition(lead: lead, signal: :sem_resposta_esgotou)
          lead.reload
          expect(lead.estado).to eq('sem_resposta')
          expect(lead.pipeline_stage_id).to eq(stage_encerrado.id)
          expect(lead.pipeline_stage_id).not_to eq(stage_futuro.id)
          expect(lead.motivo).to eq('sem_resposta_cadencia_esgotada')
        end
      end

      it 'keeps the lead reachable for reengagement in 90 days' do
        freeze_time do
          described_class.transition(lead: lead, signal: :sem_resposta_esgotou)
          lead.reload
          expect(lead.retomada_at).to eq(Time.current + 90.days)
          expect(lead.next_action_at).to eq(lead.retomada_at)
        end
      end
    end

    context 'with :pos_venda' do
      it 'sets pos_venda state with SLA, non-terminal (roteamento humano fica no n8n)' do
        freeze_time do
          described_class.transition(lead: lead, signal: :pos_venda, modelo_interesse: 'A3')
          lead.reload
          expect(lead.estado).to eq('pos_venda')
          expect(lead.status).to eq('open')
          expect(lead.next_action_at).to eq(Time.current + described_class::QUER_SLA)
          expect(lead.terminal?).to be(false)
        end
      end

      it 'does not fail when the pos_venda stage slug is absent (best-effort)' do
        expect do
          described_class.transition(lead: lead, signal: :pos_venda)
        end.not_to raise_error
        expect(lead.reload.estado).to eq('pos_venda')
      end

      it 'mirrors a lead:pos-venda label' do
        described_class.transition(lead: lead, signal: :pos_venda)
        expect(lead.conversation.reload.label_list).to include('lead:pos-venda')
      end
    end

    context 'with :outros' do
      it 'sets outros state with SLA, non-terminal' do
        freeze_time do
          described_class.transition(lead: lead, signal: :outros)
          lead.reload
          expect(lead.estado).to eq('outros')
          expect(lead.next_action_at).to eq(Time.current + described_class::QUER_SLA)
          expect(lead.terminal?).to be(false)
        end
      end

      it 'mirrors a lead:outros label' do
        described_class.transition(lead: lead, signal: :outros)
        expect(lead.conversation.reload.label_list).to include('lead:outros')
      end
    end

    context 'idempotency' do
      it 'does not create a duplicate CrmEvent when called twice with the same signal' do
        described_class.transition(lead: lead, signal: :quer)
        expect do
          described_class.transition(lead: lead, signal: :quer)
        end.not_to change { Synapseos::CrmEvent.where(event_type: 'lead_state_changed').count }
      end

      it 'does not re-resolve an already resolved conversation' do
        described_class.transition(lead: lead, signal: :nao_quer, motivo: 'x')
        expect(lead.conversation.reload.status).to eq('resolved')
        # second identical call must not raise and conversation stays resolved
        described_class.transition(lead: lead, signal: :nao_quer, motivo: 'x')
        expect(lead.conversation.reload.status).to eq('resolved')
      end
    end

    context 'invalid signal' do
      it 'raises InvalidSignal' do
        expect do
          described_class.transition(lead: lead, signal: :explode)
        end.to raise_error(described_class::InvalidSignal)
      end
    end

    context 'mirroring (I3)' do
      it 'writes custom_attributes, a state label, and a CrmEvent' do
        described_class.transition(lead: lead, signal: :quer, modelo_interesse: 'Q5')
        conv = lead.conversation.reload
        expect(conv.custom_attributes['lead_estado']).to eq('quer')
        expect(conv.custom_attributes['lead_modelo_interesse']).to eq('Q5')
        expect(conv.label_list).to include('lead:quer')
        expect(Synapseos::CrmEvent.where(conversation_id: conv.id, event_type: 'lead_state_changed')).to exist
      end

      it 'swaps the old state label for the new one' do
        described_class.transition(lead: lead, signal: :sem_resposta_toque)
        expect(lead.conversation.reload.label_list).to include('lead:sem-resposta')
        described_class.transition(lead: lead, signal: :quer)
        labels = lead.conversation.reload.label_list
        expect(labels).to include('lead:quer')
        expect(labels).not_to include('lead:sem-resposta')
      end

      it 'never lets a mirror failure abort the transition' do
        allow(Synapseos::LeadLifecycleMirror).to receive(:new).and_raise(StandardError, 'boom')
        expect do
          described_class.transition(lead: lead, signal: :quer)
        end.not_to raise_error
        expect(lead.reload.estado).to eq('quer')
      end
    end
  end
end
