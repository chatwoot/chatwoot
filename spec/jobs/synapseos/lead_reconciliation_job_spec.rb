require 'rails_helper'

RSpec.describe Synapseos::LeadReconciliationJob, type: :job do
  let(:account) { create(:account) }
  let!(:stage_futuro) do
    create(:synapseos_pipeline_stage, account: account, slug: 'futuro', name: 'Futuro', stage_type: 'open')
  end

  def build_lead(estado:, next_action_at:, conversation: nil, motivo: nil)
    conv = conversation || create(:conversation, account: account)
    lead = Synapseos::Lead.new(
      account: account, conversation: conv, status: :open,
      estado: estado, next_action_at: next_action_at, motivo: motivo
    )
    lead.save!(validate: false) # injeta violações de propósito
    lead
  end

  describe '#perform' do
    it 'repairs a non-terminal lead with nil next_action_at into Futuro+90d (I2)' do
      lead = build_lead(estado: 'sem_resposta', next_action_at: nil)

      count = described_class.new.perform

      lead.reload
      expect(lead.estado).to eq('quer_depois')
      expect(lead.next_action_at).to be_present
      expect(lead.next_action_at).to be > 80.days.from_now
      expect(count).to be >= 1
    end

    it 'repairs a non-terminal lead whose next_action_at is in the past' do
      lead = build_lead(estado: 'sem_resposta', next_action_at: 5.days.ago)

      described_class.new.perform

      lead.reload
      expect(lead.estado).to eq('quer_depois')
      expect(lead.next_action_at).to be > Time.current
    end

    it 'resolves the conversation of a terminal nao_quer lead still open (I1)' do
      conv = create(:conversation, account: account, status: :open)
      build_lead(estado: 'nao_quer', next_action_at: nil, motivo: 'sem interesse', conversation: conv)

      described_class.new.perform

      expect(conv.reload.status).to eq('resolved')
    end

    it 'leaves a healthy non-terminal lead untouched' do
      lead = build_lead(estado: 'quer', next_action_at: 1.hour.from_now)
      original = lead.next_action_at

      described_class.new.perform

      lead.reload
      expect(lead.estado).to eq('quer')
      expect(lead.next_action_at).to be_within(1.second).of(original)
    end

    it 'does NOT downgrade a quer lead past its SLA into Futuro (escalação, não nutrição)' do
      lead = build_lead(estado: 'quer', next_action_at: 3.hours.ago)
      allow(Rails.logger).to receive(:warn)

      described_class.new.perform

      lead.reload
      expect(lead.estado).to eq('quer') # não rebaixado pra quer_depois
      expect(Rails.logger).to have_received(:warn).with(/sem repair automático/)
    end

    it 'ignores legacy leads with nil estado' do
      lead = build_lead(estado: nil, next_action_at: nil)

      expect { described_class.new.perform }.not_to(change { lead.reload.estado })
    end

    it 'logs the repaired violation count' do
      build_lead(estado: 'sem_resposta', next_action_at: nil)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with(/total_violations=/)
    end
  end
end
