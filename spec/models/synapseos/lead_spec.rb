require 'rails_helper'

RSpec.describe Synapseos::Lead, type: :model do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe 'ADR-003 invariants' do
    describe 'estado inclusion' do
      it 'allows nil estado (legacy leads)' do
        lead = build(:synapseos_lead, account: account, conversation: conversation, estado: nil)
        expect(lead).to be_valid
      end

      it 'rejects an unknown estado' do
        lead = build(:synapseos_lead, account: account, conversation: conversation, estado: 'bogus')
        expect(lead).not_to be_valid
        expect(lead.errors[:estado]).to be_present
      end

      it 'accepts each known estado' do
        described_class::ESTADOS.each do |estado|
          lead = build(:synapseos_lead, account: account, conversation: conversation, estado: estado)
          # only checking the estado attribute validity here
          lead.valid?
          expect(lead.errors[:estado]).to be_empty
        end
      end
    end

    describe 'I2 — non-terminal requires next_action_at' do
      it 'is invalid when estado is non-terminal and next_action_at is nil' do
        lead = build(:synapseos_lead, account: account, conversation: conversation,
                                      estado: 'quer', next_action_at: nil)
        expect(lead).not_to be_valid
        expect(lead.errors[:next_action_at]).to be_present
      end

      it 'is valid when estado is non-terminal and next_action_at is set' do
        lead = build(:synapseos_lead, account: account, conversation: conversation,
                                      estado: 'sem_resposta', next_action_at: 1.day.from_now)
        expect(lead).to be_valid
      end

      it 'does not require next_action_at for legacy (nil estado) leads' do
        lead = build(:synapseos_lead, account: account, conversation: conversation,
                                      estado: nil, next_action_at: nil)
        expect(lead).to be_valid
      end
    end

    describe 'I1 — terminal requires motivo' do
      it 'is invalid when estado is nao_quer and motivo is blank' do
        lead = build(:synapseos_lead, account: account, conversation: conversation,
                                      estado: 'nao_quer', motivo: nil, next_action_at: nil)
        expect(lead).not_to be_valid
        expect(lead.errors[:motivo]).to be_present
      end

      it 'is valid when estado is nao_quer with a motivo and no next_action_at (terminal)' do
        lead = build(:synapseos_lead, account: account, conversation: conversation,
                                      estado: 'nao_quer', motivo: 'comprou da concorrência',
                                      next_action_at: nil)
        expect(lead).to be_valid
      end
    end

    describe '#terminal?' do
      it 'is true only for nao_quer' do
        expect(build(:synapseos_lead, estado: 'nao_quer').terminal?).to be(true)
        expect(build(:synapseos_lead, estado: 'quer').terminal?).to be(false)
        expect(build(:synapseos_lead, estado: nil).terminal?).to be(false)
      end
    end
  end
end
