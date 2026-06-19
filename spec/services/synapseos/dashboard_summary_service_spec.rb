require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS: cobre o KPI "disparos hoje" (shoots_today) do
# dashboard executivo — contatos distintos que receberam ao menos uma outgoing
# hoje (boundary BRT), independente do filtro de período.
RSpec.describe Synapseos::DashboardSummaryService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  def outgoing_to(contact, at:)
    conv = create(:conversation, account: account, inbox: inbox, contact: contact)
    create(:message, account: account, inbox: inbox, conversation: conv,
                     message_type: :outgoing, created_at: at)
  end

  describe '#call kpis[:shoots_today]' do
    it 'conta contatos DISTINTOS que receberam outgoing hoje' do
      c1 = create(:contact, account: account)
      c2 = create(:contact, account: account)
      now = Time.current
      outgoing_to(c1, at: now)
      outgoing_to(c1, at: now) # mesmo contato -> conta 1
      outgoing_to(c2, at: now)

      summary = described_class.new(account).call

      expect(summary[:kpis][:shoots_today]).to eq(2)
    end

    it 'não conta outgoings de dias anteriores' do
      contact = create(:contact, account: account)
      outgoing_to(contact, at: 2.days.ago)

      summary = described_class.new(account).call

      expect(summary[:kpis][:shoots_today]).to eq(0)
    end

    it 'não reage ao filtro de período (sempre hoje)' do
      contact = create(:contact, account: account)
      outgoing_to(contact, at: Time.current)

      # period_days curtíssimo não muda o "hoje"
      summary = described_class.new(account, period_days: 1).call

      expect(summary[:kpis][:shoots_today]).to eq(1)
    end
  end

  describe '#call dry_run (snapshot do n8n via CrmEvent)' do
    def snapshot!(meta, at: Time.current)
      Synapseos::CrmEvent.create!(account: account, event_type: 'dry_run_snapshot',
                                  metadata: meta, created_at: at)
    end

    it 'retorna nil quando não há snapshot hoje' do
      expect(described_class.new(account).call[:dry_run]).to be_nil
    end

    it 'pega o snapshot MAIS RECENTE de hoje (tarde sobre manhã)' do
      snapshot!({ 'scope' => 'manha', 'disparos' => [{ 'nome' => 'A', 'tel4' => '1111' }],
                  'followups' => [] }, at: 3.hours.ago)
      snapshot!({ 'scope' => 'tarde', 'disparos' => [{ 'nome' => 'B', 'tel4' => '2222' }],
                  'followups' => [{ 'nome' => 'C', 'tel4' => '3333' }] }, at: 1.minute.ago)

      dr = described_class.new(account).call[:dry_run]

      expect(dr[:scope]).to eq('tarde')
      expect(dr[:disparos_count]).to eq(1)
      expect(dr[:followups_count]).to eq(1)
      expect(dr[:disparos].first['nome']).to eq('B')
    end

    it 'ignora snapshot de dias anteriores' do
      snapshot!({ 'scope' => 'manha', 'disparos' => [{ 'nome' => 'X', 'tel4' => '9999' }] },
                at: 2.days.ago)
      expect(described_class.new(account).call[:dry_run]).to be_nil
    end
  end
end
